# Flutter / plugin classes are kept by their own consumer rules.
# Keep audio_service + ExoPlayer (media3) entry points used via reflection.
-keep class com.ryanheise.** { *; }
-dontwarn com.google.android.play.core.**
