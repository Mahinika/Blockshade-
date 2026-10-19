# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# AudioPlayers (Verkstad sound hooks)
-keep class xyz.luan.audioplayers.** { *; }

# shared_preferences_android (JNI / Pigeon — R8 must not strip suspend/Continuation APIs)
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclassmembers class * {
    *** getAll(...);
}
-dontwarn kotlin.coroutines.**
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Metadata { *; }

# In-App Billing
-keep class com.android.vending.billing.** { *; }

# Google Play Core (deferred components) - missing class stubs
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
