/// Backup codec: open JSON for new exports, plus the old encrypted
/// JSON → ZIP → AES-GCM format for reading existing `.etbak` files.
/// Pure Dart (archive + cryptography) — no filesystem, no network, fully
/// unit-testable. File handling lives in backup_service.dart.
///
/// Encrypted layout: salt(16) | nonce(12) | ciphertext | tag(16). Key =
/// PBKDF2-HMAC-SHA256(password, salt, 10k iterations). Wrong password fails
/// cleanly with [BackupPasswordError], never garbage output.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';

class BackupPasswordError extends ArgumentError {
  BackupPasswordError() : super('Wrong password or corrupt backup file');
}

class BackupNeedsPassword extends FormatException {
  BackupNeedsPassword() : super('This is an old encrypted backup; enter its password');
}

const backupFormat = 'expense-tracker-backup';

const _saltLen = 16;
const _nonceLen = 12;
const _tagLen = 16;
const _pbkdf2Iterations = 10000;

bool looksLikeOpenBackup(Uint8List bytes) {
  var i = 0;
  if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) i = 3;
  while (i < bytes.length && (bytes[i] == 0x20 || bytes[i] == 0x0A || bytes[i] == 0x0D || bytes[i] == 0x09)) {
    i++;
  }
  return i < bytes.length && bytes[i] == 0x7B;
}

bool looksLikeEncryptedBackup(Uint8List bytes) =>
    bytes.length >= _saltLen + _nonceLen + _tagLen + 1 && !looksLikeOpenBackup(bytes);

/// Packs [tables] into an unencrypted, human-readable JSON file.
Uint8List encodeOpenBackup(Map<String, dynamic> tables) {
  final doc = {
    'format': backupFormat,
    'v': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'tables': tables,
  };
  return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(doc)));
}

/// Reads [encodeOpenBackup] output. Throws [FormatException] for anything
/// else, including the old encrypted `.etbak`.
Map<String, dynamic> decodeOpenBackup(Uint8List bytes) {
  try {
    final doc = jsonDecode(utf8.decode(bytes));
    if (doc is! Map || doc['format'] != backupFormat || doc['tables'] is! Map) {
      throw const FormatException('Not an ExpenseTracker backup file');
    }
    return (doc['tables'] as Map).cast<String, dynamic>();
  } on FormatException {
    rethrow;
  } on Object {
    throw const FormatException('Not an ExpenseTracker backup file');
  }
}

List<int> _randomBytes(int n) {
  final r = Random.secure();
  return List<int>.generate(n, (_) => r.nextInt(256));
}

Future<SecretKey> _deriveKey(String password, List<int> salt) {
  final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _pbkdf2Iterations, bits: 256);
  return pbkdf2.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
}

/// Packs [tables] (table name → row maps) into encrypted bytes.
Future<Uint8List> encryptBackup(Map<String, dynamic> tables, String password) async {
  if (password.isEmpty) throw ArgumentError('Backup password cannot be empty');
  final payload = utf8.encode(jsonEncode({'format': 'expense-tracker-backup', 'v': 1, 'tables': tables}));
  final archive = Archive()..addFile(ArchiveFile('backup.json', payload.length, payload));
  final zipped = ZipEncoder().encode(archive);
  if (zipped == null) throw StateError('ZIP encoding failed');

  final salt = _randomBytes(_saltLen);
  final nonce = _randomBytes(_nonceLen);
  final key = await _deriveKey(password, salt);
  final box = await AesGcm.with256bits().encrypt(zipped, secretKey: key, nonce: nonce);
  return Uint8List.fromList([...salt, ...box.nonce, ...box.cipherText, ...box.mac.bytes]);
}

/// Reverses [encryptBackup]. Throws [BackupPasswordError] on wrong password
/// or tampering, [FormatException] on non-backup files.
Future<Map<String, dynamic>> decryptBackup(Uint8List packed, String password) async {
  if (packed.length < _saltLen + _nonceLen + _tagLen + 1) {
    throw const FormatException('Not an ExpenseTracker backup file');
  }
  final salt = packed.sublist(0, _saltLen);
  final nonce = packed.sublist(_saltLen, _saltLen + _nonceLen);
  final mac = Mac(packed.sublist(packed.length - _tagLen));
  final cipherText = packed.sublist(_saltLen + _nonceLen, packed.length - _tagLen);
  final key = await _deriveKey(password, salt);
  late List<int> zipped;
  try {
    zipped = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: key,
    );
  } on SecretBoxAuthenticationError {
    throw BackupPasswordError();
  }
  final archive = ZipDecoder().decodeBytes(zipped);
  ArchiveFile? file;
  for (final f in archive.files) {
    if (f.name == 'backup.json') file = f;
  }
  if (file == null) throw const FormatException('Not an ExpenseTracker backup file');
  final doc = jsonDecode(utf8.decode(file.content as List<int>)) as Map<String, dynamic>;
  if (doc['format'] != 'expense-tracker-backup') {
    throw const FormatException('Not an ExpenseTracker backup file');
  }
  return (doc['tables'] as Map).cast<String, dynamic>();
}
