package cn.quenan.duji

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 倒数日 Widget（2×2）—— 极简现代风卡片
 * 顶部蓝色标题栏 "距离{事件}还有"，中部超大数字，底部日期
 */
class CountdownWidgetProvider : AppWidgetProvider() {

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
        private const val KEY_COUNTDOWN_LIST = "countdown_list"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val views = RemoteViews(context.packageName, R.layout.countdown_widget_layout)

                val eventMapKey = "widget_$appWidgetId"
                val eventId = prefs.getString(eventMapKey, null)

                if (eventId != null) {
                    val countdownJson = prefs.getString(KEY_COUNTDOWN_LIST, "[]") ?: "[]"
                    val events = JSONArray(countdownJson)
                    var found = false
                    for (i in 0 until events.length()) {
                        val event = events.getJSONObject(i)
                        if (event.getString("id") == eventId) {
                            applyEventData(context, views, event)
                            found = true
                            break
                        }
                    }
                    if (!found) showUnconfigured(views)
                } else {
                    showUnconfigured(views)
                }

                // 点击整个小组件打开 App 的倒数日页面
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    putExtra("open_countdown", true)
                }
                val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
                views.setOnClickPendingIntent(R.id.cdw_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {
                // 静默处理
            }
        }

        private fun showUnconfigured(views: RemoteViews) {
            views.setTextViewText(R.id.cdw_title_bar, "请点击配置")
            views.setTextViewText(R.id.cdw_days_number, "--")
            views.setTextViewText(R.id.cdw_date_text, "")
        }

        private fun applyEventData(context: Context, views: RemoteViews, event: JSONObject) {
            val title = event.optString("title", "事件")
            val targetDateStr = event.optString("targetDate", "")

            if (targetDateStr.isNotEmpty()) {
                try {
                    val formats = arrayOf(
                        "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",  // +08:00
                        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",  // UTC
                        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",    // +0800
                        "yyyy-MM-dd'T'HH:mm:ss.SSS",
                        "yyyy-MM-dd'T'HH:mm:ss",
                        "yyyy-MM-dd"
                    )
                    var targetDate: Date? = null
                    for (fmt in formats) {
                        try {
                            targetDate = SimpleDateFormat(fmt, Locale.US).parse(targetDateStr)
                            break
                        } catch (_: Exception) {}
                    }

                    if (targetDate != null) {
                        val now = Date()

                        // 归一化到当天零点
                        val cal = java.util.Calendar.getInstance()
                        cal.time = now
                        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                        cal.set(java.util.Calendar.MINUTE, 0)
                        cal.set(java.util.Calendar.SECOND, 0)
                        cal.set(java.util.Calendar.MILLISECOND, 0)
                        val todayStart = cal.time

                        cal.time = targetDate
                        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                        cal.set(java.util.Calendar.MINUTE, 0)
                        cal.set(java.util.Calendar.SECOND, 0)
                        cal.set(java.util.Calendar.MILLISECOND, 0)
                        val targetStart = cal.time

                        val diffMs = targetStart.time - todayStart.time
                        val totalDays = (diffMs / (1000 * 60 * 60 * 24)).toInt()

                        views.setTextViewText(R.id.cdw_days_number, Math.abs(totalDays).toString())

                        // 标题栏：今天→"就是{title}！"  未来→"距离{title}还有"  过去→"{title}已过去"
                        val titleBarText = when {
                            totalDays == 0 -> "就是${title}！"
                            totalDays > 0 -> "距离${title}还有"
                            else -> "${title}已过去"
                        }
                        views.setTextViewText(R.id.cdw_title_bar, titleBarText)

                        // 底部日期
                        val dateFmt = SimpleDateFormat("yyyy-M-d EEE", Locale.CHINA)
                        views.setTextViewText(R.id.cdw_date_text, dateFmt.format(targetDate))
                    }
                } catch (_: Exception) {
                    views.setTextViewText(R.id.cdw_days_number, "--")
                    views.setTextViewText(R.id.cdw_date_text, "")
                }
            } else {
                views.setTextViewText(R.id.cdw_days_number, "--")
                views.setTextViewText(R.id.cdw_date_text, "")
            }
        }

        fun refreshWidget(context: Context, appWidgetId: Int) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }

        fun refreshAll(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val allKeys = prefs.all.keys
            val widgetIds = allKeys.filter { it.startsWith("widget_") }
                .mapNotNull { it.removePrefix("widget_").toIntOrNull() }
            val appWidgetManager = AppWidgetManager.getInstance(context)
            for (id in widgetIds) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }
    }
}
