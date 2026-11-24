package com.taotao.taotao

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.util.Calendar

/**
 * Widget de la casita de los gatitos.
 *
 * La app (lib/widgets/casita_widget_sync.dart) guarda con home_widget:
 *   img_casita_dia, img_casita_tarde, img_casita_noche (rutas de PNG),
 *   casita_pescaditos, casita_meta_nombre y casita_meta_precio (alcancía).
 * Aquí se elige el dibujo según la hora, igual que en la app
 * (de 7 a 17 de día, 18 y 19 de tarde, de 20 a 6 de noche).
 */
class CasitaWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.casita_widget)
            llenar(v, widgetData)
            v.setOnClickPendingIntent(
                R.id.casita_raiz,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(id, v)
        }
    }

    private fun llenar(v: RemoteViews, datos: SharedPreferences) {
        val hora = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        val momento = when {
            hora >= 20 || hora < 7 -> "noche"
            hora >= 18 -> "tarde"
            else -> "dia"
        }
        val ruta = datos.getString("img_casita_$momento", null)
            ?: datos.getString("img_casita_dia", null)
        val bitmap = ruta?.let { File(it) }?.takeIf { it.exists() }
            ?.let { BitmapFactory.decodeFile(it.absolutePath) }
        if (bitmap != null) {
            v.setImageViewBitmap(R.id.casita_dibujo, bitmap)
        } else {
            v.setImageViewResource(R.id.casita_dibujo, android.R.color.transparent)
        }

        if (ruta == null) {
            v.setTextViewText(R.id.casita_texto, "Abre la app")
            v.setViewVisibility(R.id.casita_alcancia, View.GONE)
            return
        }
        val pescaditos = datos.getInt("casita_pescaditos", 0)
        val meta = datos.getString("casita_meta_nombre", null)
        val precio = datos.getInt("casita_meta_precio", 0)
        if (meta != null && precio > 0) {
            v.setTextViewText(R.id.casita_texto, "🐷 $meta: $pescaditos/$precio")
            v.setViewVisibility(R.id.casita_alcancia, View.VISIBLE)
            v.setProgressBar(
                R.id.casita_alcancia, 100,
                (pescaditos * 100 / precio).coerceIn(0, 100), false,
            )
        } else {
            v.setTextViewText(R.id.casita_texto, "🐟 $pescaditos pescaditos")
            v.setViewVisibility(R.id.casita_alcancia, View.GONE)
        }
    }
}
