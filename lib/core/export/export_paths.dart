/// Where anything this app writes ends up: **Downloads/ExpenseTracker/** on
/// the phone.
///
/// The old behaviour put the encrypted backup in the private app documents
/// directory, which no file manager shows — the owner had no idea where the
/// file was, so a backup was effectively useless. `getExternalStorageDirectory`
/// maps to `Android/data/<pkg>/files` on modern Android, which is *also*
/// hidden, so this walks the public Downloads directory instead and falls
/// back through the app's own directories if the OS refuses.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sub-folder inside Downloads, so the app's files are easy to find and easy
/// to clear in one go.
const exportFolderName = 'ExpenseTracker';

class ExportPaths {
  const ExportPaths(this.directory);

  /// Resolved directory plus the label to show the owner ("Downloads/…").
  final Directory directory;

  String get displayPath {
    final parts = directory.path.split('/').where((e) => e.isNotEmpty).toList();
    final index = parts.lastIndexOf('Download');
    if (index >= 0 && index + 1 < parts.length) return parts.sublist(index).join('/');
    return directory.path;
  }

  File file(String name) => File(p.join(directory.path, name));

  /// `expensetracker-2026-09-27-1830-<tag>.<ext>`
  File stamped(String extension, {String tag = ''}) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}-${two(now.month)}-${two(now.day)}-${two(now.hour)}${two(now.minute)}';
    final suffix = tag.isEmpty ? '' : '-$tag';
    return file('expensetracker-$stamp$suffix.$extension');
  }

  /// Downloads/ExpenseTracker, created on first use.
  static Future<ExportPaths> resolve() async {
    final candidates = <String>[];
    // Android's public Downloads. `getDownloadsPath` is not available across
    // all platforms, so the well-known absolute path is tried first and the
    // platform helpers after.
    const androidId = 'com.android.externalstorage';
    try {
      final storage = await _envDownloads();
      candidates.add(p.join(storage, 'Download', exportFolderName));
    } on Object {
      // fall through
    }
    candidates.add(p.join(androidId, 'Download', exportFolderName));
    try {
      candidates.add(p.join((await getExternalStorageDirectory())!.path, exportFolderName));
    } on Object {
      // fall through
    }
    candidates.add(p.join((await getApplicationDocumentsDirectory()).path, exportFolderName));

    for (final path in candidates) {
      try {
        final dir = Directory(path);
        if (await dir.create(recursive: true) == dir) return ExportPaths(dir);
      } on Object {
        // try the next one
      }
    }
    // Nothing was writable — fall back to the documents directory so a write
    // still succeeds rather than failing silently.
    return ExportPaths(await getApplicationDocumentsDirectory());
  }

  static Future<String> _envDownloads() async {
    if (Platform.isAndroid) return '/storage/emulated/0';
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) return p.join(home, '.local', 'share');
    }
    if (Platform.isMacOS) return p.join(Platform.environment['HOME'] ?? '/', 'Downloads');
    throw UnsupportedError('no downloads path');
  }
}