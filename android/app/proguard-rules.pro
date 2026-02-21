# Ignore missing OkHttp classes for uCrop
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.yalantis.ucrop.**
-keep class com.yalantis.ucrop.** { *; }
-keep class com.yalantis.ucrop.task.** { *; }