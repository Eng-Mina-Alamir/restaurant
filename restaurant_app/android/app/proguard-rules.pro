# ==============================================================================
# 🛡️ Proguard & R8 Optimization Rules — مطعم ليالي المحروسة
# ==============================================================================

# Flutter & Core Framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Models, Freezed & JSON Serialization
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Supabase & WebSockets
-dontwarn io.supabase.**
-keep class io.supabase.** { *; }
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Sentry Crash Reporting
-keepattributes LineNumberTable,SourceFile
-dontwarn com.getsentry.**
-keep class com.getsentry.** { *; }

# Google Fonts & Media Plugins
-dontwarn com.google.fonts.**
-dontwarn com.ryanheise.audioservice.**

# Google Play Core & Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
