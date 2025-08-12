# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep ProGuard annotations - this addresses the missing proguard.annotation.Keep error
-dontwarn proguard.annotation.**
-keep class proguard.annotation.** { *; }
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keepclassmembers @proguard.annotation.KeepClassMembers class * { *; }

# Keep Kotlin metadata and suppress compatibility warnings
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Suppress Kotlin version mismatch warnings
-dontwarn kotlin.reflect.jvm.internal.**
-dontwarn org.jetbrains.kotlin.**

# Keep serialization classes
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Keep classes that use reflection
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes with custom constructors
-keepclassmembers class * {
    public <init>(...);
}

# Firebase specific rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep all plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class com.example.** { *; }
