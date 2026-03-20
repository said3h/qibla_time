// android/app/src/main/kotlin/com/qiblatime/qibla_time/MainActivity.kt
//
// Reemplaza el contenido actual de MainActivity con este código,
// o si ya tienes código en configureFlutterEngine, añade solo
// el bloque del MethodChannel dentro.

package com.qiblatime.qibla_time

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val DND_CHANNEL = "com.qiblatime/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DND_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "enableDnd" -> {
                    val granted = enableDnd()
                    result.success(granted)
                }

                "disableDnd" -> {
                    disableDnd()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun enableDnd(): Boolean {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        // Android 6+ requiere permiso especial para DND
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!nm.isNotificationPolicyAccessGranted) {
                // Abrir ajustes para que el usuario conceda el permiso
                val intent = Intent(
                    Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS
                )
                startActivity(intent)
                return false
            }
        }

        nm.setInterruptionFilter(
            NotificationManager.INTERRUPTION_FILTER_NONE
        )
        return true
    }

    private fun disableDnd() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!nm.isNotificationPolicyAccessGranted) return
        }

        nm.setInterruptionFilter(
            NotificationManager.INTERRUPTION_FILTER_ALL
        )
    }
}
