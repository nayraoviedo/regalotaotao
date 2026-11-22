import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fullscreen_stub.dart'
    if (dart.library.js_interop) 'fullscreen_web.dart'
    as fullscreen;

/// "Bloquear pantalla" del pomodoro, para no salirse y perder el tiempo.
///
/// - Android: fija la app (fijación de pantalla del sistema). Para salir hay
///   que desbloquear desde la app o mantener Atrás + Recientes.
/// - Web: pantalla completa (el navegador siempre deja salir con Esc).
/// - iPhone: oculta las barras; para bloquear de verdad hay que usar
///   "Acceso guiado" de iOS.
class FocusLock {
  FocusLock._();

  static const _channel = MethodChannel('taotao/foco');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> lock() async {
    if (kIsWeb) {
      await fullscreen.enter();
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (isAndroid) {
      try {
        await _channel.invokeMethod<void>('lock');
      } on PlatformException {
        // Si el sistema no lo permite, igual queda en pantalla completa.
      } on MissingPluginException {
        // Ídem.
      }
    }
  }

  static Future<void> unlock() async {
    if (kIsWeb) {
      await fullscreen.exit();
      return;
    }
    if (isAndroid) {
      try {
        await _channel.invokeMethod<void>('unlock');
      } on PlatformException {
        // Nada que hacer.
      } on MissingPluginException {
        // Ídem.
      }
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
