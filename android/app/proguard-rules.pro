# R8 rules for ExpenseTracker.
#
# --- ML Kit (on-device OCR) -------------------------------------------------
# ML Kit loads its bundled text-recogniser implementation **by class name** at
# runtime. Without these rules R8 renames or deletes those classes in the
# minified release build, the lookup returns null, and the recogniser dies
# with:
#   NullPointerException: Attempt to invoke virtual method
#   'java.lang.Class java.lang.Object.getClass()' on a null object reference
#   at sc2.<init>(...) ... at gk.run(Handler.java:938)
# (which is ML Kit's own code after obfuscation — the debug build always
# worked, every release APK did not).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text** { *; }
# The bundled Latin model is part of the app, so it must survive too.
-keep class com.google.mlkit.vision.text.bundled.** { *; }
-keep class com.google.mlkit.vision.text.latin.** { *; }
-dontwarn com.google.mlkit.**

# The OCR plugin's code references the Chinese, Devanagari, Japanese and
# Korean recogniser option classes that this app does not ship (recognition is
# Latin-only, offline). R8 treats the references as missing classes and fails
# the release build, so they are warned out here. These are the exact rules
# AGP generated in build/app/outputs/mapping/release/missing_rules.txt.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
