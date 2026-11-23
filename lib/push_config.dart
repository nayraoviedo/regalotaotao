/// Dirección del Worker de Cloudflare que envía las notificaciones push
/// ("te extraño", invitaciones de pomodoro y premios).
///
/// Después de `npx wrangler deploy` (ver README.md, sección "Notificaciones
/// push"), pega aquí la dirección que te muestra, sin "/" al final. Ejemplo:
///   const notificationsUrl = 'https://taotao-notificaciones.tu-nombre.workers.dev';
///
/// No es un secreto: el Worker solo acepta pedidos de personas que iniciaron
/// sesión, y solo avisa a su pareja.
const notificationsUrl =
    'https://taotao-notificaciones.nayraoviedo.workers.dev';
