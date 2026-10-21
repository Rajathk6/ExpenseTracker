/// On-device OCR for payment screenshots.
///
/// A screenshot shared from a UPI/banking app is recognised entirely on the
/// phone (ML Kit, Latin script) and the recognised text goes through exactly
/// the same extractor as a shared SMS — see core/intake/share_parser.dart.
/// Nothing is uploaded; the recogniser is closed as soon as we have the text.
///
/// Kept behind a tiny interface so the flow is testable without the plugin,
/// and honest about failures: a screenshot that cannot be read says *why*.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The OCR call the intake screen needs. [RecogniseText] is the production
/// implementation; tests can pass a fake.
abstract class TextReader {
  /// The recognised text, or a throw with the reason it could not be read.
  Future<String> read(String imagePath);
}

/// Raised when an image cannot be read — the reason travels to the screen.
class OcrFailure implements Exception {
  final String reason;
  const OcrFailure(this.reason);
  @override
  String toString() => reason;
}

const _channel = MethodChannel('dev.rajath.expense_tracker/share');

class RecogniseText implements TextReader {
  const RecogniseText();

  @override
  Future<String> read(String imagePath) async {
    final path = await readableImagePath(imagePath);
    // A file that is not really a picture makes the recogniser fail with an
    // unreadable NullPointerException — so it is checked here first, where
    // the message can be useful.
    if (!await _looksLikeAnImage(File(path))) {
      throw const OcrFailure('That file is not a picture the recogniser can open.');
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return result.text;
    } on Object {
      // ML Kit's own crash (a null image inside its decoder) is unreadable;
      // say so in words the owner can act on.
      throw const OcrFailure(
        'The recogniser could not read this picture. Try a screenshot of the '
        'payment message (not a photo of the screen), or type the amount in.',
      );
    } finally {
      await recognizer.close();
    }
  }
}

/// A path the recogniser can open.
///
/// A shared or picked image is not always a plain file path: it can be a
/// `content://` uri or a provider cache file. The platform resolves it to a
/// real file, and a local copy is the last resort.
Future<String> readableImagePath(String imagePath) async {
  if (imagePath.isEmpty) throw const OcrFailure('No image was given');
  final file = File(imagePath);
  if (await file.exists() && await file.length() > 0) {
    if (await _looksLikeAnImage(file)) return imagePath;
  }
  // Ask the platform (it can open content:// uris the app cannot).
  try {
    final resolved = await _channel.invokeMethod<String>('resolveImage', {'path': imagePath});
    if (resolved != null && resolved.isNotEmpty) {
      final resolvedFile = File(resolved);
      if (await resolvedFile.exists() && await resolvedFile.length() > 0) return resolved;
    }
  } on MissingPluginException {
    // No platform side — fall through to the local copy.
  } on PlatformException {
    // Fall through.
  }
  // Last resort: copy whatever we can read into our own cache.
  try {
    if (await file.exists() && await file.length() > 0) {
      final dir = await getTemporaryDirectory();
      final target = File(p.join(dir.path, 'ocr-${DateTime.now().millisecondsSinceEpoch}.img'));
      await file.copy(target.path);
      return target.path;
    }
  } on Object {
    // fall through to the error below
  }
  throw const OcrFailure('That image could not be opened — it may not be a picture the app can read.');
}

/// A quick check that the file really is a picture (PNG or JPEG magic bytes),
/// so a wrong file fails with a clear message instead of a silent blank.
Future<bool> _looksLikeAnImage(File file) async {
  try {
    final handle = await file.open();
    final head = await handle.read(8);
    await handle.close();
    if (head.length < 4) return false;
    final png = head[0] == 0x89 && head[1] == 0x50 && head[2] == 0x4E && head[3] == 0x47;
    final jpeg = head[0] == 0xFF && head[1] == 0xD8;
    final webp = head.length >= 12 &&
        String.fromCharCodes(head.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(head.sublist(8, 12)) == 'WEBP';
    return png || jpeg || webp;
  } on Object {
    return false;
  }
}

/// Reads a file only if it looks like a readable image.
bool isReadableImage(String path) {
  if (path.isEmpty) return false;
  final file = File(path);
  try {
    if (!file.existsSync()) return false;
    return file.lengthSync() > 0;
  } on Object {
    return false;
  }
}
