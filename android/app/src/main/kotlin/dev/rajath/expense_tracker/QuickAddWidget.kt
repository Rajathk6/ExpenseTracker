package dev.rajath.expense_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home-screen tile for ExpenseTracker: shows the month's spend and opens the
 * 2-tap quick-add sheet. The numbers are written from Dart via
 * [HomeWidgetPlugin]; the tap is a launch intent that comes back as
 * `homewidget://quickadd?action=quickadd`, handled in lib/features/cash.
 */
class QuickAddWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget).apply {
                setTextViewText(
                    R.id.widget_title,
                    widgetData.getString("title", context.getString(R.string.app_name)),
                )
                setTextViewText(R.id.widget_spend, widgetData.getString("spend", "—"))
                setTextViewText(R.id.widget_budget, widgetData.getString("budget", ""))
                setTextViewText(R.id.widget_hint, widgetData.getString("hint", "Tap to add"))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("homewidget://quickadd?action=quickadd"),
                    ),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
