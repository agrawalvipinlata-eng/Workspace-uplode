package com.srbs.never_miss_bus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.util.Calendar

/**
 * 📱 NEVER MISS BUS — phone HOME SCREEN widget (Duolingo style).
 * School logo + greeting + one-tap open to live bus tracking.
 * No network calls here (free, battery-safe) — greeting time-based.
 */
class NmbHomeWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.nmb_home_widget)

            // Time-based friendly message (Duolingo vibe)
            val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            val status = when {
                hour in 5..9 -> "🌅 Good Morning! Bus check kar lo 🚌"
                hour in 10..13 -> "🏫 School time! Sab set hai ✓"
                hour in 14..17 -> "🚌 Wapsi ki bus track karo!"
                else -> "🌙 Kal ki bus ready — Good Night!"
            }
            views.setTextViewText(R.id.widget_status, status)

            // Tap anywhere → open app
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pi = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
