import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The OCR crash that shipped in every release build.
///
/// ML Kit loads its bundled text recogniser **by class name** at runtime. R8
/// (which the release build runs) renamed and *deleted* those classes, so the
/// lookup returned null and the recogniser died with:
///   NullPointerException: Attempt to invoke virtual method
///   'java.lang.Class java.lang.Object.getClass()' on a null object reference
///   at sc2.<init>(...) ... at gk.run(Handler.java:938)
///
/// The debug build never showed it (no R8), so it only ever appeared in the
/// APKs the owner installed. The fix is ProGuard keep rules — this test is
/// here so they cannot be dropped again without noticing.
void main() {
  test('the release build keeps ML Kit\'s bundled recogniser', () {
    final rules = File('android/app/proguard-rules.pro');
    expect(rules.existsSync(), true, reason: 'the ProGuard rules file is gone');

    final text = rules.readAsStringSync();
    expect(
      text,
      contains('-keep class com.google.mlkit.** { *; }'),
      reason: 'ML Kit must not be shrunk or renamed',
    );
    expect(
      text,
      contains('-keep class com.google.android.gms.internal.mlkit_vision_text** { *; }'),
      reason: 'the classes ML Kit loads by name must survive',
    );
  });

  test('the release build is actually minified (so the rules matter)', () {
    // If R8 ever stops running for the release build, the rules are harmless
    // but the test above is no longer the thing standing between us and the
    // crash. This pins the assumption.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('proguardFiles('));
  });
}
