package com.example.moto_dash

// Author: Ujwal N K /w Claude
// Created: 2026.08.07
//
// Native side of the `in.madilu.motodash/voice_notes` MethodChannel.
// Saves a finished recording (a temp file written by the `record` package)
// into the public Downloads/MotoDash Voice Memos folder.
//
// - Android 10+ (API 29+): MediaStore Downloads collection. No storage
//   permission required for files the app writes itself; the destination
//   folder is created automatically the first time a file is inserted into
//   it via RELATIVE_PATH.
// - Android 9 and below: direct file write under the public Downloads
//   directory (requires WRITE_EXTERNAL_STORAGE, declared with
//   maxSdkVersion="28" in the manifest), followed by a media scan so the
//   file shows up immediately in file managers / other apps.
//
// Wire this up the same way as your existing per-feature channel handlers
// (telephony, assistant, permissions) — call
// `VoiceNoteStorageHandler.register(flutterEngine, this)` from
// MainActivity.configureFlutterEngine().

//package in.madilu.motodash


import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.OutputStream

class VoiceNoteStorageHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "in.madilu.motodash/voice_notes"
        private const val RELATIVE_DIR = "MotoDash Voice Memos"
        private const val MIME_TYPE = "audio/mp4" // .m4a (AAC-LC in an MP4 container)

        fun register(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(
                VoiceNoteStorageHandler(context.applicationContext)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveToDownloads" -> handleSave(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleSave(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        val fileName = call.argument<String>("fileName")

        if (filePath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "filePath and fileName are required", null)
            return
        }

        val sourceFile = File(filePath)
        if (!sourceFile.exists()) {
            result.error("FILE_NOT_FOUND", "Source file does not exist: $filePath", null)
            return
        }

        try {
            val saved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveViaMediaStore(sourceFile, fileName)
            } else {
                saveLegacy(sourceFile, fileName)
            }

            if (saved != null) {
                result.success(saved)
            } else {
                result.error("SAVE_FAILED", "Could not save recording to Downloads", null)
            }
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message, null)
        }
    }

    /** Android 10+ — MediaStore Downloads collection. */
    private fun saveViaMediaStore(sourceFile: File, fileName: String): String? {
        val resolver = context.contentResolver

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, MIME_TYPE)
            put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$RELATIVE_DIR")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val itemUri: Uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return null

        var success = false
        try {
            resolver.openOutputStream(itemUri)?.use { out: OutputStream ->
                FileInputStream(sourceFile).use { input -> input.copyTo(out) }
                success = true
            }
        } finally {
            if (success) {
                val doneValues = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
                resolver.update(itemUri, doneValues, null, null)
            } else {
                // Don't leave a broken, empty row behind.
                resolver.delete(itemUri, null, null)
            }
        }

        return if (success) itemUri.toString() else null
    }

    /** Android 9 and below — direct file write + media scan. */
    private fun saveLegacy(sourceFile: File, fileName: String): String? {
        val downloadsDir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            RELATIVE_DIR,
        )
        if (!downloadsDir.exists() && !downloadsDir.mkdirs()) {
            return null
        }

        val destFile = File(downloadsDir, fileName)
        FileInputStream(sourceFile).use { input ->
            FileOutputStream(destFile).use { output -> input.copyTo(output) }
        }

        // Make the file visible in Downloads / other media apps immediately,
        // instead of waiting for the next full media scan.
        MediaScannerConnection.scanFile(context, arrayOf(destFile.absolutePath), arrayOf(MIME_TYPE), null)

        return destFile.absolutePath
    }
}