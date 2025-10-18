# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes (adjust package name if needed)
-keep class com.example.salespulse.models.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Image picker
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Permissions handler
-keep class com.baseflow.permissionhandler.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Local notifications
-keep class com.dexterous.** { *; }

# Play Core Library (required for Flutter embedding)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
