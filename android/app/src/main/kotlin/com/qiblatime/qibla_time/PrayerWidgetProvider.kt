// android/app/src/main/kotlin/com/qiblatime/qibla_time/PrayerWidgetProvider.kt
//
// Widget de pantalla de inicio para Android.
// Lee los datos que WidgetSyncService guarda via home_widget package
// y los muestra en el widget.

package com.qiblatime.qibla_time

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.*

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        // Estas keys deben coincidir EXACTAMENTE con las que usa
        // WidgetSyncService en Flutter (home_widget package)
        private const val PREFS_NAME   = "HomeWidgetPreferences"
        private const val KEY_PRAYER   = "next_prayer_name"
        private const val KEY_TIME     = "next_prayer_time"
        private const val KEY_COUNTDOWN= "next_prayer_countdown"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(
                PREFS_NAME, Context.MODE_PRIVATE
            )

            // Leer datos guardados por Flutter / WidgetSyncService
            val prayerName = prefs.getString(KEY_PRAYER,    "—") ?: "—"
            val prayerTime = prefs.getString(KEY_TIME,      "—") ?: "—"
            val countdown  = prefs.getString(KEY_COUNTDOWN, "—") ?: "—"

            val views = RemoteViews(context.packageName, R.layout.prayer_widget)

            // Actualizar textos
            views.setTextViewText(R.id.widget_prayer_name,  prayerName)
            views.setTextViewText(R.id.widget_prayer_time,  prayerTime)
            views.setTextViewText(R.id.widget_countdown,    "En $countdown")

            // Botón — abre la app al tocar cualquier parte del widget
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
