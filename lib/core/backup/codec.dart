/// Encrypted backup codec: JSON → ZIP → password-encrypted bytes and back.
/// Pure Dart (archive + cryptography) — no filesystem, no network, fully
/// unit-testable. File/Drive handling lives in backup_service.dart.
///
/// Layout: salt(16) | nonce(12) | ciphertext | tag(16). Key = PBKDF2-HMAC-
/// SHA256(password, salt, 10k iterations). Wrong password fails cleanly
/// with [BackupPasswordError] (GCM tag mismatch), never garbage output.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';

class BackupPasswordError extends ArgumentError {
  BackupPasswordError() : super('Wrong password or corrupt backup file');
}

const _saltLen = 16;
const _nonceLen = 12;
const _tagLen = 16;
const _pbkdf2Iterations = 10000;

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
