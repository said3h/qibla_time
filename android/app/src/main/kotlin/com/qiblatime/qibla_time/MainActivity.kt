// android/app/src/main/kotlin/com/qiblatime/qibla_time/MainActivity.kt
//
// Reemplaza el contenido actual de MainActivity con este código,
// o si ya tienes código en configureFlutterEngine, añade solo
// el bloque del MethodChannel dentro.

package com.qiblatime.qibla_time

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, SensorEventListener {

    private val DND_CHANNEL = "com.qiblatime/dnd"
    private val PROXIMITY_CHANNEL = "com.qiblatime/proximity"
    private val TAG = "QiblaProximity"

    private var sensorManager: SensorManager? = null
    private var proximitySensor: Sensor? = null
    private var proximityEventSink: EventChannel.EventSink? = null
    private var lastSentValue: Int = -1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PROXIMITY_CHANNEL
        ).setStreamHandler(this)

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

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "onListen: Starting proximity sensor stream")
        proximityEventSink = events
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        proximitySensor = sensorManager?.getDefaultSensor(Sensor.TYPE_PROXIMITY)

        if (proximitySensor == null) {
            Log.e(TAG, "onListen: PROXIMITY sensor NOT available on this device")
            proximityEventSink?.error(
                "PROXIMITY_UNAVAILABLE",
                "This device does not expose a proximity sensor.",
                "Sensor type: TYPE_PROXIMITY, Max range: N/A"
            )
            return
        }

        Log.d(TAG, "onListen: Sensor found - maxRange=${proximitySensor!!.maximumRange}, resolution=${proximitySensor!!.resolution}, type=${proximitySensor!!.type}")
        
        // Use FASTEST for sujud detection (normal movement)
        sensorManager?.registerListener(
            this,
            proximitySensor,
            SensorManager.SENSOR_DELAY_FASTEST
        )
        Log.d(TAG, "onListen: Sensor registered with SENSOR_DELAY_FASTEST")
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "onCancel: Stopping proximity sensor stream")
        sensorManager?.unregisterListener(this)
        proximityEventSink = null
        lastSentValue = -1
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (proximityEventSink == null) return

        val sensor = proximitySensor ?: return
        val distance = event?.values?.firstOrNull() ?: return

        // ALL proximity sensors report:
        // - Near: distance value LOWER than maximumRange (typically 0.0 cm)
        // - Far:  distance value EQUAL to maximumRange (typically 5.0 cm)
        // This works for both discrete (binary) and continuous sensors.
        val isNear = distance < sensor.maximumRange
        
        Log.d(TAG, "onSensorChanged: distance=$distance cm, maxRange=${sensor.maximumRange} cm, isNear=$isNear")

        val currentValue = if (isNear) 1 else 0

        // Only send if value changed (reduce noise)
        if (currentValue != lastSentValue) {
            lastSentValue = currentValue
            proximityEventSink?.success(currentValue)
            Log.d(TAG, "onSensorChanged: Sent value=$currentValue to Flutter")
        } else {
            Log.v(TAG, "onSensorChanged: Value unchanged ($currentValue), skipping")
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        val accuracyStr = when (accuracy) {
            SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> "HIGH"
            SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> "MEDIUM"
            SensorManager.SENSOR_STATUS_ACCURACY_LOW -> "LOW"
            SensorManager.SENSOR_STATUS_UNRELIABLE -> "UNRELIABLE"
            else -> "UNKNOWN"
        }
        Log.d(TAG, "onAccuracyChanged: sensor=${sensor?.name}, accuracy=$accuracyStr")
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
