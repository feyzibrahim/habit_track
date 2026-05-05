package com.app.ezecute

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MinimalWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout_minimal).apply {
                // Load the image rendered by Flutter
                val imagePath = widgetData.getString("minimalWidgetImage", null)
                if (imagePath != null) {
                    setImageViewUri(R.id.widget_image_minimal, Uri.parse(imagePath))
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
