package cn.quenan.duji

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

/**
 * 我的物品统计 Widget
 * 显示物品数量、总价值、日均价格，与 App 内 StatsCardWidget 数据同步
 */
class EquipmentWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "widget_data"
        private const val KEY_EQUIPMENT_COUNT = "equipment_count"
        private const val KEY_EQUIPMENT_TOTAL = "equipment_total"
        private const val KEY_EQUIPMENT_AVG = "equipment_avg"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val views = RemoteViews(context.packageName, R.layout.equipment_widget_layout)

                val count = prefs.getInt(KEY_EQUIPMENT_COUNT, 0)
                val totalValue = prefs.getFloat(KEY_EQUIPMENT_TOTAL, 0f)
                val avgPrice = prefs.getFloat(KEY_EQUIPMENT_AVG, 0f)

                views.setTextViewText(R.id.widget_equipment_count, count.toString())
                views.setTextViewText(
                    R.id.widget_total_value,
                    if (count > 0) "¥${java.lang.Math.round(totalValue)}" else "¥0"
                )
                views.setTextViewText(
                    R.id.widget_average_price,
                    if (count > 0) "¥${java.lang.Math.round(avgPrice)}" else "¥0"
                )

                // Tap opens app
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent, flags
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {
                // 静默处理，避免 widget 崩溃
            }
        }
    }
}
