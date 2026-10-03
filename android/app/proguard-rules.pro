# Flutter's own embedding classes are referenced from generated/reflective
# code paths that R8 can't always trace statically.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Razorpay Checkout — per Razorpay's own Android integration guide, R8/
# ProGuard must not touch its SDK classes or the payment result callbacks.
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Truecaller SDK — its OAuth callback classes are invoked reflectively.
-keep class com.truecaller.android.sdk.** { *; }
-dontwarn com.truecaller.android.sdk.**

# Play services (SMS Retriever / Auth) used directly from MainActivity.kt.
-keep class com.google.android.gms.auth.api.phone.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

# Firebase Messaging payload/token callbacks.
-keep class com.google.firebase.messaging.** { *; }

# Standard safety net: Parcelable CREATORs and enum valueOf/values() are
# common R8 stripping casualties that only surface as runtime crashes.
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
