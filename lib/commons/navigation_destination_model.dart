// Author: Ujwal N K /w Claude
// Created: 2026.08.02
// Simple value type for a saved navigation destination.

class NavigationDestinationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const NavigationDestinationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Reconstructs a favourite from a "name|lat|lng" value paired with its map key (id).
  factory NavigationDestinationModel.fromEntry(String id, String value) {
    final parts = value.split('|');
    return NavigationDestinationModel(
      id: id,
      name: parts[0],
      latitude: double.parse(parts[1]),
      longitude: double.parse(parts[2]),
    );
  }

  /// Encodes this favourite as a single delimited string, to be stored as the map value.
  String toEntryValue() => '$name|$latitude|$longitude';

  NavigationDestinationModel copyWith({String? name, double? latitude, double? longitude}) {
    return NavigationDestinationModel(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
