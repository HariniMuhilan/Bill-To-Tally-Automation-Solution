# ProGuard/R8 Rules for BillBooks Mobile App

# Google ML Kit Text Recognition
# Suppress warnings for optional language packs (Chinese, Devanagari, Japanese, Korean)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }

# Flutter & Supabase
-dontwarn io.flutter.**
-dontwarn io.supabase.**

