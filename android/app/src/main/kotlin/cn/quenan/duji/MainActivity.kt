package cn.quenan.duji

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "cn.quenan.duji/widgets"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateEquipmentWidget" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args != null) {
                        saveEquipmentData(args)
                        updateEquipmentWidgets()
                    }
                    result.success(true)
                }
                "updateCountdownWidget" -> {
                    val countdownList = call.arguments as? String
                    if (countdownList != null) {
                        saveCountdownData(countdownList)
                        updateCountdownWidgets()
                    }
                    result.success(true)
                }
                "updateAllWidgets" -> {
                    val args = call.arguments as? Map<String, Any>
                    val equipmentData = args?.get("equipment") as? Map<String, Any>
                    val countdownData = args?.get("countdown") as? String

                    if (equipmentData != null) saveEquipmentData(equipmentData)
                    if (countdownData != null) saveCountdownData(countdownData)

                    updateEquipmentWidgets()
                    updateCountdownWidgets()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 检查是否从倒数日小组件打开 — 通知 Flutter 切换到倒数日标签页
        if (intent?.getBooleanExtra("open_countdown", false) == true) {
            Handler(Looper.getMainLooper()).postDelayed({
                MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    CHANNEL
                ).invokeMethod("openCountdownTab", null)
            }, 200)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // App 已在运行的情况
        if (intent.getBooleanExtra("open_countdown", false)) {
            flutterEngine?.let { engine ->
                Handler(Looper.getMainLooper()).postDelayed({
                    MethodChannel(
                        engine.dartExecutor.binaryMessenger,
                        CHANNEL
                    ).invokeMethod("openCountdownTab", null)
                }, 200)
            }
        }
    }

    private fun saveEquipmentData(args: Map<String, Any>) {
        val prefs = getSharedPreferences("widget_data", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putInt("equipment_count", (args["count"] as? Int) ?: 0)
            putFloat("equipment_total", (args["totalValue"] as? Double)?.toFloat() ?: 0f)
            putFloat("equipment_avg", (args["averagePrice"] as? Double)?.toFloat() ?: 0f)
            apply()
        }
    }

    private fun saveCountdownData(jsonString: String) {
        val prefs = getSharedPreferences("widget_data", Context.MODE_PRIVATE)
        prefs.edit().putString("countdown_list", jsonString).apply()
    }

    private fun updateEquipmentWidgets() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val widgetIds = appWidgetManager.getAppWidgetIds(
            android.content.ComponentName(this, EquipmentWidgetProvider::class.java)
        )
        for (id in widgetIds) {
            EquipmentWidgetProvider.updateAppWidget(this, appWidgetManager, id)
        }
    }

    private fun updateCountdownWidgets() {
        CountdownWidgetProvider.refreshAll(this)
    }
}
