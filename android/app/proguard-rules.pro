# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Supabase / GoTrue
-keep class com.supabase.** { *; }

# PDF (Printing plugin uses reflection on some classes)
-keep class com.google.android.gms.internal.consent_sdk.** { *; }

# Prevent stripping of native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core (referenced by Flutter's deferred-components path; we don't use it)
-dontwarn com.google.android.play.core.**
