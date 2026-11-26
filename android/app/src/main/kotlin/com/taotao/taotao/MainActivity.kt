package com.taotao.taotao

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // "Bloquear pantalla" del pomodoro: fija la app con la fijación de
    // pantalla de Android para que no se pueda salir sin querer.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taotao/foco")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "lock" -> try {
                        startLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("lock", e.message, null)
                    }
                    "unlock" -> try {
                        stopLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("unlock", e.message, null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Alarma de los recordatorios: ahorro de batería, pantalla completa
        // y ajustes del canal (ver lib/services/alarma_recordatorios.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taotao/alarma")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "bateriaLibre" -> {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            result.success(
                                Build.VERSION.SDK_INT < 23 ||
                                    pm.isIgnoringBatteryOptimizations(packageName)
                            )
                        }
                        "pedirBateria" -> {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            if (Build.VERSION.SDK_INT >= 23 &&
                                !pm.isIgnoringBatteryOptimizations(packageName)
                            ) {
                                try {
                                    startActivity(
                                        Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                            .setData(Uri.parse("package:$packageName"))
                                    )
                                } catch (e: Exception) {
                                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                                }
                            }
                            result.success(null)
                        }
                        "pantallaCompleta" -> {
                            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                            result.success(
                                Build.VERSION.SDK_INT < 34 || nm.canUseFullScreenIntent()
                            )
                        }
                        "abrirCanal" -> {
                            val canal = call.argument<String>("canal")
                            val intent = if (Build.VERSION.SDK_INT >= 26 && canal != null) {
                                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                    .putExtra(Settings.EXTRA_CHANNEL_ID, canal)
                            } else {
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                    .setData(Uri.parse("package:$packageName"))
                            }
                            startActivity(intent)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("alarma", e.message, null)
                }
            }
    }
}
