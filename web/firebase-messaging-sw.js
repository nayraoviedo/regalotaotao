// Recibe las notificaciones push de Taotao en el navegador ("Te extraño",
// invitaciones al pomodoro, premios…) cuando la pestaña está cerrada o en
// segundo plano. Las manda el Worker de Cloudflare (carpeta worker/), igual
// que en Android.
//
// La configuración de Firebase la pone Firebase Hosting en /__/firebase/init.js,
// así que este archivo no lleva claves. En `flutter run -d web-server` (en tu
// compu) ese archivo no existe: ahí no hay push web y la app sigue normal.

// Al tocar la notificación, abre Taotao (o enfoca la pestaña si ya está
// abierta). Va antes de cargar Firebase para que se ejecute primero.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const inicio = new URL('./', self.location.href).href;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((lista) => {
      for (const c of lista) {
        if (c.url.startsWith(inicio) && 'focus' in c) return c.focus();
      }
      return clients.openWindow(inicio);
    })
  );
});

try {
  importScripts(
    'https://www.gstatic.com/firebasejs/11.10.0/firebase-app-compat.js',
    'https://www.gstatic.com/firebasejs/11.10.0/firebase-messaging-compat.js',
    '/__/firebase/init.js'
  );
  // Con esto Firebase muestra sola la notificación que manda el Worker.
  firebase.messaging();
} catch (e) {
  console.warn('Taotao: sin notificaciones push en esta dirección.', e);
}
