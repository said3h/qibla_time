// android/app/src/main/kotlin/com/qiblatime/qibla_time/MainActivity.kt
//
// Reemplaza el contenido actual de MainActivity con este código,
// o si ya tienes código en configureFlutterEngine, añade solo
// el bloque del MethodChannel dentro.

package com.qiblatime.mobile

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.util.concurrent.Executors
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean

import com.qiblatime.mobile.video.StillVideoExporter

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, SensorEventListener {

    private val DND_CHANNEL = "com.qiblatime/dnd"
    private val PROXIMITY_CHANNEL = "com.qiblatime/proximity"
    private val SETTINGS_CHANNEL = "com.qiblatime/android_settings"
    private val VIDEO_EXPORT_CHANNEL = "com.qiblatime/video_export"
    private val GALLERY_CHANNEL = "com.qiblatime/gallery"
    private val TAG = "QiblaProximity"
    private val VIDEO_TAG = "QiblaVideoExport"
    private val GALLERY_TAG = "QiblaGallery"
    // Generous timeout: Ayat Al-Kursi is ~2 min audio → ~3 600 frames to encode
    // plus AAC decode/re-encode in the same loop.  20 s was far too short and
    // caused every long ayah to be cancelled before the export could finish.
    private val VIDEO_TIMEOUT_MS = 300_000L
    private val VIDEO_TIMEOUT_MESSAGE = "El vídeo tardó demasiado y se canceló"

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
        val galleryExecutor = Executors.newSingleThreadExecutor()
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

                    val mainHandler = Handler(Looper.getMainLooper())
                    val completed = AtomicBoolean(false)
                    val timeoutRunnable = Runnable {
                        if (completed.compareAndSet(false, true)) {
                            val lastStep = StillVideoExporter.lastActiveStep()
                            Log.e(
                                VIDEO_TAG,
                                "Native export timeout after ${VIDEO_TIMEOUT_MS}ms lastStep=$lastStep"
                            )
                            StillVideoExporter.cancelActiveExport()
                            result.error(
                                "EXPORT_TIMEOUT",
                                "$VIDEO_TIMEOUT_MESSAGE\nÚltimo paso nativo: $lastStep",
                                mapOf(
                                    "type" to "ExportTimeout",
                                    "message" to VIDEO_TIMEOUT_MESSAGE,
                                    "lastStep" to lastStep
                                )
                            )
                        }
                    }
                    mainHandler.postDelayed(timeoutRunnable, VIDEO_TIMEOUT_MS)

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
                            runOnUiThread {
                                if (completed.compareAndSet(false, true)) {
                                    mainHandler.removeCallbacks(timeoutRunnable)
                                    result.success(outputPath)
                                } else {
                                    Log.w(VIDEO_TAG, "Native export completed after timeout; result already sent")
                                }
                            }
                        } catch (e: Throwable) {
                            val fullError = e.fullStackTrace()
                            Log.e(VIDEO_TAG, "Native export failed:\n$fullError", e)
                            runOnUiThread {
                                if (completed.compareAndSet(false, true)) {
                                    mainHandler.removeCallbacks(timeoutRunnable)
                                    result.error(
                                        "EXPORT_FAILED",
                                        fullError,
                                        mapOf(
                                            "type" to e.javaClass.name,
                                            "message" to (e.message ?: "Video export failed"),
                                            "stackTrace" to fullError,
                                            "lastStep" to StillVideoExporter.lastActiveStep()
                                        )
                                    )
                                } else {
                                    Log.e(VIDEO_TAG, "Native export failed after timeout; result already sent", e)
                                }
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GALLERY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveVideoToGallery" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "Missing video path", null)
                        return@setMethodCallHandler
                    }

                    galleryExecutor.execute {
                        try {
                            val saved = saveVideoToGallery(path)
                            runOnUiThread {
                                result.success(saved)
                            }
                        } catch (e: Throwable) {
                            val fullError = e.fullStackTrace()
                            Log.e(GALLERY_TAG, "Failed to save video to gallery:\n$fullError", e)
                            runOnUiThread {
                                result.error(
                                    "SAVE_VIDEO_FAILED",
                                    e.message ?: "Failed to save video.",
                                    mapOf(
                                        "type" to e.javaClass.name,
                                        "message" to (e.message ?: "Failed to save video."),
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

    private fun saveVideoToGallery(videoPath: String): Boolean {
        val sourceFile = File(videoPath)
        require(sourceFile.exists()) { "Video file does not exist." }
        require(sourceFile.length() > 0L) { "Video file is empty." }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveVideoWithMediaStore(sourceFile)
        } else {
            saveVideoLegacy(sourceFile)
        }
    }

    private fun saveVideoWithMediaStore(sourceFile: File): Boolean {
        val resolver = contentResolver
        val displayName = galleryVideoFileName(sourceFile)
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/QiblaTime")
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("Could not create gallery video entry.")

        return try {
            resolver.openOutputStream(uri)?.use { output ->
                sourceFile.inputStream().use { input ->
                    input.copyTo(output)
                }
            } ?: error("Could not open gallery output stream.")

            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            Log.i(GALLERY_TAG, "Video saved to gallery uri=$uri")
            true
        } catch (e: Throwable) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    private fun saveVideoLegacy(sourceFile: File): Boolean {
        val moviesDirectory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
        val targetDirectory = File(moviesDirectory, "QiblaTime")
        if (!targetDirectory.exists() && !targetDirectory.mkdirs()) {
            error("Could not create gallery directory.")
        }

        val targetFile = uniqueLegacyVideoFile(targetDirectory, galleryVideoFileName(sourceFile))
        sourceFile.copyTo(targetFile, overwrite = false)
        MediaScannerConnection.scanFile(
            this,
            arrayOf(targetFile.absolutePath),
            arrayOf("video/mp4"),
            null
        )
        Log.i(GALLERY_TAG, "Video saved to gallery path=${targetFile.absolutePath}")
        return true
    }

    private fun galleryVideoFileName(sourceFile: File): String {
        val baseName = sourceFile.nameWithoutExtension
            .takeIf { it.isNotBlank() }
            ?: "qiblatime_video"
        return "${baseName}_${System.currentTimeMillis()}.mp4"
    }

    private fun uniqueLegacyVideoFile(directory: File, fileName: String): File {
        val baseName = fileName.substringBeforeLast('.', fileName)
        val extension = fileName.substringAfterLast('.', "mp4")
        var candidate = File(directory, fileName)
        var index = 1
        while (candidate.exists()) {
            candidate = File(directory, "${baseName}_$index.$extension")
            index += 1
        }
        return candidate
    }

    private fun Throwable.fullStackTrace(): String {
        val stringWriter = StringWriter()
        val printWriter = PrintWriter(stringWriter)
        printStackTrace(printWriter)
        printWriter.flush()
        return stringWriter.toString()
    }
}
