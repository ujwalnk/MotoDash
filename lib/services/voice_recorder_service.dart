// Author: Ujwal N K /w Claude
// Created: 2026.08.07
// Owns the lifecycle of voice-memo recordings. No UI code lives here —
// pages drive this service and reflect isRecording / lastError in their
// own DashActions / TTS calls.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:moto_dash/bridges/voice_note_storage_bridge.dart';
import 'package:moto_dash/commons/permission_check.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum VoiceRecorderError { microphonePermissionDenied, alreadyRecording, notRecording, recorderFailure, storageFailure }

class VoiceRecorderException implements Exception {
  final VoiceRecorderError error;
  final String message;

  VoiceRecorderException(this.error, this.message);

  @override
  String toString() => 'VoiceRecorderException($error): $message';
}

/// Manages start/stop/save of voice-memo recordings, backed by the `record`
/// package. Saving is delegated to [VoiceNoteStorageBridge], which hands the
/// finished file to native MediaStore code — this service never touches
/// public storage directly.
///
/// Interruptions (calls, permission loss, recorder failure) are treated as a
/// normal recording completion: whatever was captured is finalized and
/// saved, never silently discarded.
class VoiceRecorderService extends ChangeNotifier {
  VoiceRecorderService._();

  static final VoiceRecorderService instance = VoiceRecorderService._();

  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// The most recent error, if any. Cleared at the start of every
  /// start/stop call. Pages can read this after a failed call to decide
  /// what to announce via TTS.
  VoiceRecorderException? lastError;

  String? _tempFilePath;
  String? _pendingFileName;

  static const RecordConfig _config = RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000);

  /// Starts a new recording into a private cache file. Returns true on
  /// success. On failure this populates [lastError] and returns false
  /// rather than throwing, so callers don't need try/catch boilerplate for
  /// the common "permission denied" / "already recording" cases.
  Future<bool> startRecording() async {
    lastError = null;

    if (_isRecording) {
      lastError = VoiceRecorderException(VoiceRecorderError.alreadyRecording, 'A recording is already in progress.');
      return false;
    }

    // Belt-and-braces: the dashboard only shows Voice Note once permissions
    // are granted, but re-check here since this service can be driven from
    // anywhere (e.g. a future hardware-button binding).
    final hasPermission = await PermissionCheck.hasVoiceNotePermissions();
    if (!hasPermission) {
      lastError = VoiceRecorderException(
        VoiceRecorderError.microphonePermissionDenied,
        'Microphone permission is not granted.',
      );
      return false;
    }

    try {
      final cacheDir = await getTemporaryDirectory();
      final fileName = _buildFileName();
      final tempPath = '${cacheDir.path}/$fileName';

      await _recorder.start(_config, path: tempPath);

      _tempFilePath = tempPath;
      _pendingFileName = fileName;
      _isRecording = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isRecording = false;
      lastError = VoiceRecorderException(VoiceRecorderError.recorderFailure, 'Failed to start recording: $e');
      return false;
    }
  }

  /// Stops the active recording and saves it to
  /// `Downloads/MotoDash Voice Memos`. Returns the resulting content URI
  /// (Android 10+) or absolute file path (legacy Android) on success, or
  /// null if nothing was recording or the save failed — check [lastError]
  /// for details in that case.
  Future<String?> stopRecording() async {
    lastError = null;

    if (!_isRecording) {
      lastError = VoiceRecorderException(VoiceRecorderError.notRecording, 'No recording is in progress.');
      return null;
    }

    String? recordedPath;
    try {
      recordedPath = await _recorder.stop();
    } catch (e) {
      lastError = VoiceRecorderException(VoiceRecorderError.recorderFailure, 'Failed to stop recording cleanly: $e');
    } finally {
      _isRecording = false;
      notifyListeners();
    }

    // `stop()` can return null on some recorder failures even though the
    // file was actually written — fall back to the path we started with.
    recordedPath ??= _tempFilePath;
    final fileName = _pendingFileName;
    _tempFilePath = null;
    _pendingFileName = null;

    if (recordedPath == null || fileName == null) {
      lastError ??= VoiceRecorderException(VoiceRecorderError.recorderFailure, 'No audio file was produced.');
      return null;
    }

    final file = File(recordedPath);
    if (!await file.exists() || await file.length() == 0) {
      lastError = VoiceRecorderException(
        VoiceRecorderError.recorderFailure,
        'Recording produced an empty or missing file.',
      );
      await _safeDelete(file);
      return null;
    }

    try {
      final savedUri = await VoiceNoteStorageBridge.saveToDownloads(filePath: recordedPath, fileName: fileName);
      await _safeDelete(file);

      if (savedUri == null) {
        lastError = VoiceRecorderException(VoiceRecorderError.storageFailure, 'Failed to save recording to Downloads.');
        return null;
      }

      return savedUri;
    } catch (e) {
      await _safeDelete(file);
      lastError = VoiceRecorderException(VoiceRecorderError.storageFailure, 'Failed to save recording: $e');
      return null;
    }
  }

  Future<void> toggleRecording() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// Called by [CallStateListener] when an incoming or outgoing call
  /// interrupts an active recording. Finalizes and saves the recording —
  /// this is treated as a normal completion, never a discard — then lets
  /// the call flow continue uninterrupted.
  Future<void> handleCallInterruption() async {
    if (!_isRecording) return;
    await stopRecording();
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup of the temp file; the saved copy in Downloads
      // (if any) is what actually matters to the user.
    }
  }

  String _buildFileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'MotoDash_$stamp.m4a';
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
