/// On-device OCR for payment screenshots.
///
/// A screenshot shared from a UPI/banking app is recognised entirely on the
/// phone (ML Kit, Latin script) and the recognised text goes through exactly
/// the same extractor as a shared SMS — see core/intake/share_parser.dart.
/// Nothing is uploaded; the recogniser is closed as soon as we have the text.
///
/// Kept behind a tiny interface so the flow is testable without the plugin.
library;

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The OCR call the intake screen needs. [RecogniseText] is the production
/// implementation; tests can pass a fake.
abstract class TextReader {
  Future<String> read(String imagePath);
}

class RecogniseText implements TextReader {
  const RecogniseText();

  /// ML Kit models are large; [TextRecognizer] is created per call and closed
  /// right after, so an abandoned intake screen cannot leak it.
  @override
  Future<String> read(String imagePath) async {
    // A picked or shared image is not always a plain readable path (it can be
    // a content:// URI or a provider cache file). Copy it into our own cache
    // so the recogniser always gets a real file.
    final path = await _readableCopy(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  /// A path the recogniser can open: the file itself, or a copy of it.
  Future<String> _readableCopy(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists() && await file.length() > 0) return imagePath;
    final dir = await getTemporaryDirectory();
    final target = File(p.join(dir.path, 'ocr-${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await file.copy(target.path);
    return target.path;
  }
}

/// Reads a file only if it looks like a readable image — a share can hand us
/// a content:// path the OS will not let us read directly.
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
