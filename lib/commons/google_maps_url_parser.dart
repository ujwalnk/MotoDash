// Author: Ujwal N K /w Claude
// Created: 2026.08.02
// Extracts a (latitude, longitude) pair from a Google Maps URL, resolving shortened links first if needed.

import 'dart:io';

class GoogleMapsUrlParser {
  /// Checked in priority order: a place pin's actual coordinate (!3d!4d) takes precedence over the map's center
  /// coordinate (@lat,lng), since for named places these can differ slightly - the pin is what the user meant.
  static final List<RegExp> _patterns = [
    RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)'),
    RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)'),
    RegExp(r'[?&]ll=(-?\d+\.\d+),(-?\d+\.\d+)'),
    RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)'),
  ];

  /// Attempts to extract coordinates from a Google Maps URL (or any text containing one). Returns null if none of
  /// the known patterns match, even after resolving a shortened link.
  static Future<(double, double)?> extractLatLng(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final direct = _tryExtract(trimmed);
    if (direct != null) return direct;

    if (_looksShortened(trimmed)) {
      final resolved = await _resolveRedirects(trimmed);
      if (resolved != null) {
        final fromResolved = _tryExtract(resolved);
        if (fromResolved != null) return fromResolved;
      }
    }

    return null;
  }

  static bool _looksShortened(String url) {
    return url.contains('goo.gl') || url.contains('maps.app');
  }

  static (double, double)? _tryExtract(String url) {
    for (final pattern in _patterns) {
      final match = pattern.firstMatch(url);
      if (match == null) continue;
      final a = double.tryParse(match.group(1)!);
      final b = double.tryParse(match.group(2)!);
      if (a != null && b != null) return (a, b);
    }
    return null;
  }

  /// Manually follows HTTP redirects (rather than letting HttpClient auto-follow) since we need the final resolved
  /// URL string, not just its response body. Capped at 5 hops as a safety net against redirect loops.
  static Future<String?> _resolveRedirects(String url) async {
    final client = HttpClient();
    try {
      Uri? current = Uri.tryParse(url);
      if (current == null) return null;

      for (int i = 0; i < 5; i++) {
        final request = await client.getUrl(current!);
        request.followRedirects = false;
        final response = await request.close();

        if (response.statusCode >= 300 && response.statusCode < 400) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          await response.drain();
          if (location == null) return current.toString();
          current = current.resolve(location);
          continue;
        }

        await response.drain();
        return current.toString();
      }
      return current?.toString();
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
