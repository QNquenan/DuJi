package cn.quenan.duji

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.ListView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 倒数日 Widget 配置 Activity
 * 现代化卡片列表，与 App 内 _CountdownTile 样式一致
 */
class CountdownWidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var eventList: List<CountdownItem>

    data class CountdownItem(
        val id: String,
        val emoji: String,
        val title: String,
        val dateStr: String,
        val statusText: String,
        val statusColor: Int,
        val diffValue: Int    // 用于排序等
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.countdown_widget_config_layout)

        appWidgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            setResult(Activity.RESULT_CANCELED)
            finish()
            return
        }

        eventList = loadCountdownEvents()

        val listView = findViewById<ListView>(R.id.event_list)
        listView.adapter = EventListAdapter(this, eventList)
        listView.setOnItemClickListener { _, _, position, _ ->
            val selected = eventList[position]
            saveWidgetEventMapping(appWidgetId, selected.id)

            val appWidgetManager = AppWidgetManager.getInstance(this)
            CountdownWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)

            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(Activity.RESULT_OK, resultValue)
            finish()
        }
    }

    private fun loadCountdownEvents(): List<CountdownItem> {
        val prefs = getSharedPreferences("widget_data", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("countdown_list", "[]") ?: "[]"
        val items = mutableListOf<CountdownItem>()

        try {
            val arr = JSONArray(jsonStr)
            val now = Date()
            val nowCal = java.util.Calendar.getInstance()
            val dateFormats = arrayOf(
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd"
            )

            for (i in 0 until arr.length()) {
                val event = arr.getJSONObject(i)
                val id = event.getString("id")
                val emoji = event.optString("emoji", "📅")
                val title = event.optString("title", "事件")
                val type = event.optString("type", "days")
                val targetDateStr = event.optString("targetDate", "")

                var dateStr = ""
                var statusText = ""
                var statusColor = 0
                var diffValue = 0

                if (targetDateStr.isNotEmpty()) {
                    try {
                        var targetDate: Date? = null
                        for (fmt in dateFormats) {
                            try {
                                targetDate = SimpleDateFormat(fmt, Locale.US).parse(targetDateStr)
                                break
                            } catch (_: Exception) {}
                        }

                        if (targetDate != null) {
                            val dateFmt = SimpleDateFormat("yyyy-M-d", Locale.CHINA)
                            dateStr = dateFmt.format(targetDate)

                            // 归一化到零点比较
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
                            diffValue = Math.abs(totalDays)

                            // 与 Flutter _CountdownTile 一致的状态文字
                            if (type == "anniversary") {
                                // 周年计算：年数差异
                                val tCal = java.util.Calendar.getInstance().apply {
                                    time = targetDate!!
                                }
                                val years = nowCal.get(java.util.Calendar.YEAR) - tCal.get(java.util.Calendar.YEAR)
                                val m = nowCal.get(java.util.Calendar.MONTH) - tCal.get(java.util.Calendar.MONTH)
                                val d = nowCal.get(java.util.Calendar.DAY_OF_MONTH) - tCal.get(java.util.Calendar.DAY_OF_MONTH)
                                val y = if (m < 0 || (m == 0 && d < 0)) years - 1 else years
                                statusText = "已经 $y 周年"
                                statusColor = Color.parseColor("#FF1A73E8")
                            } else if (totalDays > 0) {
                                statusText = "还有 $totalDays 天"
                                statusColor = if (totalDays <= 7) Color.parseColor("#FFFF9800") else Color.parseColor("#FF1A73E8")
                            } else if (totalDays == 0) {
                                statusText = "就是今天！"
                                statusColor = Color.parseColor("#FFFF9800")
                            } else {
                                statusText = "已经 ${-totalDays} 天"
                                statusColor = Color.parseColor("#FF666666")
                            }
                        }
                    } catch (_: Exception) {}
                }

                items.add(CountdownItem(id, emoji, title, dateStr, statusText, statusColor, diffValue))
            }
        } catch (_: Exception) {}

        return items
    }

    private fun saveWidgetEventMapping(widgetId: Int, eventId: String) {
        val prefs = getSharedPreferences("widget_data", Context.MODE_PRIVATE)
        prefs.edit().putString("widget_$widgetId", eventId).apply()
    }

    private class EventListAdapter(
        private val context: Context,
        private val items: List<CountdownItem>
    ) : BaseAdapter() {

        override fun getCount() = items.size
        override fun getItem(position: Int) = items[position]
        override fun getItemId(position: Int) = position.toLong()

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView ?: LayoutInflater.from(context)
                .inflate(R.layout.countdown_config_item, parent, false)

            val item = items[position]

            view.findViewById<TextView>(R.id.item_emoji).text = item.emoji
            view.findViewById<TextView>(R.id.item_title).text = item.title
            view.findViewById<TextView>(R.id.item_date).text = item.dateStr

            val statusView = view.findViewById<TextView>(R.id.item_days)
            statusView.text = item.statusText
            statusView.setTextColor(item.statusColor)

            return view
        }
    }
}
