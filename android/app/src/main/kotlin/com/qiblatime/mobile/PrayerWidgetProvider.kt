package com.qiblatime.mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

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
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val KEY_PRAYER = "next_prayer_name"
        private const val KEY_TIME = "next_prayer_time"
        private const val KEY_COUNTDOWN = "next_prayer_countdown"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )

            val dash = "\u2014"
            val prayerName = prefs.getString(KEY_PRAYER, dash) ?: dash
            val prayerTime = prefs.getString(KEY_TIME, dash) ?: dash
            val countdown = prefs.getString(KEY_COUNTDOWN, dash) ?: dash
            val countdownPrefix = context.getString(R.string.widget_countdown_prefix).trim()
            val countdownText = if (countdownPrefix.isBlank()) {
                countdown
            } else {
                "$countdownPrefix $countdown"
            }

            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            views.setTextViewText(R.id.widget_prayer_name, prayerName)
            views.setTextViewText(R.id.widget_prayer_time, prayerTime)
            views.setTextViewText(R.id.widget_countdown, countdownText)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
