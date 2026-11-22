package com.taotao.taotao

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
    }
}
