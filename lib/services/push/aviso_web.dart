import 'package:web/web.dart' as web;

/// Con la pestaña abierta, Firebase no muestra la notificación del Worker:
/// la mostramos nosotros con la API de notificaciones del navegador.
void mostrarAvisoWeb(String? titulo, String? texto) {
  try {
    if (web.Notification.permission != 'granted') return;
    web.Notification(
      titulo ?? '星月',
      web.NotificationOptions(body: texto ?? '', icon: 'icons/Icon-192.png'),
    );
  } catch (_) {
    // Algunos navegadores (p. ej. Android Chrome) no dejan crearla así.
  }
}
