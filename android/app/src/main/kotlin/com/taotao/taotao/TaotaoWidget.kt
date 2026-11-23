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
import java.util.TimeZone

/**
 * Widget de la pantalla de inicio: días juntos y el ánimo de tu pareja.
 *
 * Los datos los guarda la app (lib/services/widget_celular/) con home_widget:
 *   vinculados, dias_inicio (yyyy-MM-dd), pareja_nombre, pareja_animo_id,
 *   pareja_animo_label, img_gatitos, img_animo_<id> (rutas de PNG).
 * Los días se cuentan aquí, así el número cambia solo cada día.
 */
class TaotaoWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val vistas = RemoteViews(context.packageName, R.layout.taotao_widget)
            llenar(vistas, widgetData)
            // Tocar el widget abre la app.
            vistas.setOnClickPendingIntent(
                R.id.widget_raiz,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(id, vistas)
        }
    }

    private fun llenar(v: RemoteViews, datos: SharedPreferences) {
        ponerImagen(v, R.id.widget_gatitos, datos.getString("img_gatitos", null))

        if (!datos.getBoolean("vinculados", false)) {
            v.setTextViewText(R.id.widget_dias, "♡")
            v.setTextViewText(R.id.widget_dias_texto, "Taotao")
            v.setViewVisibility(R.id.widget_animo, View.GONE)
            v.setTextViewText(R.id.widget_pareja, "")
            v.setTextViewText(R.id.widget_animo_texto, "Abre la app y vincúlate")
            return
        }

        val dias = diasDesde(datos.getString("dias_inicio", null))
        if (dias == null) {
            v.setTextViewText(R.id.widget_dias, "♡")
            v.setTextViewText(R.id.widget_dias_texto, "Pon su fecha\nen Nosotros")
        } else {
            v.setTextViewText(R.id.widget_dias, dias.toString())
            v.setTextViewText(
                R.id.widget_dias_texto,
                if (dias == 1L) "día juntos" else "días juntos",
            )
        }

        val nombre = datos.getString("pareja_nombre", null)?.takeIf { it.isNotBlank() }
            ?: "Tu pareja"
        val animoId = datos.getString("pareja_animo_id", null)
        val animo = datos.getString("pareja_animo_label", null)
        v.setViewVisibility(R.id.widget_animo, View.VISIBLE)
        if (animoId == null || animo == null) {
            ponerImagen(v, R.id.widget_animo, null)
            v.setTextViewText(R.id.widget_pareja, nombre)
            v.setTextViewText(R.id.widget_animo_texto, "aún no cuenta\ncómo está")
        } else {
            ponerImagen(v, R.id.widget_animo, datos.getString("img_animo_$animoId", null))
            v.setTextViewText(R.id.widget_pareja, "$nombre se siente")
            v.setTextViewText(R.id.widget_animo_texto, animo)
        }
    }

    private fun ponerImagen(v: RemoteViews, vista: Int, ruta: String?) {
        val bitmap = ruta
            ?.let { File(it) }
            ?.takeIf { it.exists() }
            ?.let { BitmapFactory.decodeFile(it.absolutePath) }
        if (bitmap != null) {
            v.setImageViewBitmap(vista, bitmap)
        } else {
            v.setImageViewResource(vista, android.R.color.transparent)
        }
    }

    /** Días entre la fecha guardada y hoy, contando por fecha (no por horas). */
    private fun diasDesde(fecha: String?): Long? {
        val partes = fecha?.split("-")?.mapNotNull { it.toIntOrNull() } ?: return null
        if (partes.size != 3) return null
        val hoy = Calendar.getInstance()
        val utc = TimeZone.getTimeZone("UTC")
        fun dia(anio: Int, mes: Int, d: Int): Long = Calendar.getInstance(utc).run {
            clear()
            set(anio, mes, d)
            timeInMillis / 86_400_000L
        }
        val inicio = dia(partes[0], partes[1] - 1, partes[2])
        val ahora = dia(hoy.get(Calendar.YEAR), hoy.get(Calendar.MONTH), hoy.get(Calendar.DAY_OF_MONTH))
        return (ahora - inicio).coerceAtLeast(0)
    }
}
