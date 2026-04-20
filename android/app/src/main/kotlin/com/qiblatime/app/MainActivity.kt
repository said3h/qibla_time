// android/app/src/main/kotlin/com/qiblatime/qibla_time/MainActivity.kt
//
// Reemplaza el contenido actual de MainActivity con este código,
// o si ya tienes código en configureFlutterEngine, añade solo
// el bloque del MethodChannel dentro.

package com.qiblatime.app

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.PrintWriter
import java.io.StringWriter
import java.util.concurrent.Executors
import java.util.Locale

import com.qiblatime.app.video.StillVideoExporter

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, SensorEventListener {

    private val DND_CHANNEL = "com.qiblatime/dnd"
    private val PROXIMITY_CHANNEL = "com.qiblatime/proximity"
    private val SETTINGS_CHANNEL = "com.qiblatime/android_settings"
    private val VIDEO_EXPORT_CHANNEL = "com.qiblatime/video_export"
    private val TAG = "QiblaProximity"
    private val VIDEO_TAG = "QiblaVideoExport"

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SETTINGS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    result.success(openNotificationSettings())
                }

                "openExactAlarmSettings" -> {
                    result.success(openExactAlarmSettings())
                }

                "openBatterySettings" -> {
                    val manufacturer =
                        call.argument<String>("manufacturer").orEmpty()
                    result.success(openBatterySettings(manufacturer))
                }

                else -> result.notImplemented()
            }
        }

        val videoExecutor = Executors.newSingleThreadExecutor()
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VIDEO_EXPORT_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "exportStillVideo" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val audioPath = call.argument<String>("audioPath")
                    val outputPath = call.argument<String>("outputPath")
                    val width = call.argument<Int>("width") ?: 1080
                    val height = call.argument<Int>("height") ?: 1920
                    val fps = call.argument<Int>("fps") ?: 30
                    val videoBitrate = call.argument<Int>("videoBitrate") ?: 2_500_000
                    val audioBitrate = call.argument<Int>("audioBitrate") ?: 192_000

                    if (imagePath.isNullOrBlank() || audioPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "Missing imagePath/audioPath/outputPath", null)
                        return@setMethodCallHandler
                    }

                    Log.i(
                        VIDEO_TAG,
                        "MethodChannel exportStillVideo requested image=$imagePath audio=$audioPath output=$outputPath size=${width}x$height fps=$fps"
                    )

                    videoExecutor.execute {
                        try {
                            Log.i(VIDEO_TAG, "Native export worker started")
                            StillVideoExporter.export(
                                StillVideoExporter.Params(
                                    imagePath = imagePath,
                                    audioPath = audioPath,
                                    outputPath = outputPath,
                                    width = width,
                                    height = height,
                                    fps = fps,
                                    videoBitrate = videoBitrate,
                                    audioBitrate = audioBitrate,
                                )
                            )
                            Log.i(VIDEO_TAG, "Native export worker finished successfully output=$outputPath")
                            runOnUiThread { result.success(outputPath) }
                        } catch (e: Throwable) {
                            val fullError = e.fullStackTrace()
                            Log.e(VIDEO_TAG, "Native export failed:\n$fullError", e)
                            runOnUiThread {
                                result.error(
                                    "EXPORT_FAILED",
                                    fullError,
                                    mapOf(
                                        "type" to e.javaClass.name,
                                        "message" to (e.message ?: "Video export failed"),
                                        "stackTrace" to fullError
                                    )
                                )
                            }
                        }
                    }
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

    private fun openNotificationSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
            if (startSettingsIntent(intent)) return true
        }

        return openAppDetails()
    }

    private fun openExactAlarmSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:$packageName")
            }
            if (startSettingsIntent(intent)) return true
        }

        return openAppDetails()
    }

    private fun openBatterySettings(manufacturer: String): Boolean {
        val brand = manufacturer.lowercase(Locale.ROOT)
        val appLabel = applicationInfo.loadLabel(packageManager).toString()
        val intents = mutableListOf<Intent>()

        when {
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> {
                intents += Intent().apply {
                    setClassName(
                        "com.miui.powerkeeper",
                        "com.miui.powerkeeper.ui.HiddenAppsConfigActivity"
                    )
                    putExtra("package_name", packageName)
                    putExtra("package_label", appLabel)
                }
                intents += Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                    putExtra("extra_pkgname", packageName)
                }
                intents += Intent().apply {
                    setClassName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    )
                }
            }

            brand.contains("huawei") || brand.contains("honor") -> {
                intents += Intent().apply {
                    setClassName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                    )
                }
                intents += Intent().apply {
                    setClassName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.optimize.process.ProtectActivity"
                    )
                }
            }

            brand.contains("samsung") -> {
                intents += Intent("com.samsung.android.sm.ACTION_BATTERY")
                intents += Intent().apply {
                    setClassName(
                        "com.samsung.android.lool",
                        "com.samsung.android.sm.ui.battery.BatteryActivity"
                    )
                }
            }

            brand.contains("oppo") || brand.contains("realme") || brand.contains("oneplus") -> {
                intents += Intent().apply {
                    setClassName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.startupapp.StartupAppListActivity"
                    )
                }
                intents += Intent().apply {
                    setClassName(
                        "com.oplus.safecenter",
                        "com.oplus.safecenter.startupapp.StartupAppListActivity"
                    )
                }
            }

            brand.contains("vivo") || brand.contains("iqoo") -> {
                intents += Intent().apply {
                    setClassName(
                        "com.iqoo.secure",
                        "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
                    )
                }
            }
        }

        intents += Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        intents += Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)

        for (intent in intents) {
            if (startSettingsIntent(intent)) return true
        }

        return openAppDetails()
    }

    private fun openAppDetails(): Boolean {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
        }
        return startSettingsIntent(intent)
    }

    private fun startSettingsIntent(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun Throwable.fullStackTrace(): String {
        val stringWriter = StringWriter()
        val printWriter = PrintWriter(stringWriter)
        printStackTrace(printWriter)
        printWriter.flush()
        return stringWriter.toString()
    }
}
