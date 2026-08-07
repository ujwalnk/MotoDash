// Author: Ujwal N K /w Claude
// Created: 2026.08.07
// Native bridge - kotlin platform integration through channel [in.madilu.motodash/voice_notes]
//
// Saves finished voice-memo recordings into the public
// Downloads/MotoDash Voice Memos folder via MediaStore (Android 10+) or a
// direct file copy + media scan (Android 9 and below). VoiceRecorderService
// should be the only caller of this bridge — it owns the recorder itself,
// this just owns getting the finished file into public storage.

import 'package:flutter/services.dart';

abstract class VoiceNoteStorageBridge {
  static const MethodChannel _channel = MethodChannel('in.madilu.motodash/voice_notes');

  /// Copies the temp file at [filePath] into `Downloads/MotoDash Voice
  /// Memos` as [fileName], creating the folder if it doesn't exist yet.
  /// Returns the resulting content URI (or absolute path on legacy
  /// Android) on success, or null on failure.
  static Future<String?> saveToDownloads({required String filePath, required String fileName}) async {
    try {
      return await _channel.invokeMethod<String>('saveToDownloads', {'filePath': filePath, 'fileName': fileName});
    } on PlatformException {
      return null;
    }
  }
}
