# ──────────────────────────────────────────────────────────────────────────────
# flutter_local_notifications
# R8 en release elimina/ofusca estas clases si no se protegen explícitamente.
# ──────────────────────────────────────────────────────────────────────────────
-keep class com.dexterous.** { *; }
-keepnames class com.dexterous.** { *; }

# BroadcastReceivers declarados en AndroidManifest deben sobrevivir a R8
-keep public class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
-keep public class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
-keep public class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin

# ──────────────────────────────────────────────────────────────────────────────
# Flutter engine y plugins
# ──────────────────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ──────────────────────────────────────────────────────────────────────────────
# Gson / serialización JSON (usado por flutter_local_notifications internamente)
# ──────────────────────────────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ──────────────────────────────────────────────────────────────────────────────
# permission_handler
# ──────────────────────────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ──────────────────────────────────────────────────────────────────────────────
# home_widget
# ──────────────────────────────────────────────────────────────────────────────
-keep class es.antonborri.home_widget.** { *; }

# ──────────────────────────────────────────────────────────────────────────────
# Receivers y clases propias de la app
# ──────────────────────────────────────────────────────────────────────────────
-keep class com.qiblatime.app.** { *; }

# ──────────────────────────────────────────────────────────────────────────────
# Generales Android
# ──────────────────────────────────────────────────────────────────────────────
-keepclassmembers class * extends android.content.BroadcastReceiver { *; }
-keepclassmembers class * extends android.app.Service { *; }
-keepclassmembers class * extends android.app.Activity { *; }
