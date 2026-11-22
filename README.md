# Taotao 💞

App de pareja hecha en **Flutter** con **Firebase**.

Cada persona crea su cuenta y recibe un **código de pareja** de 6 letras.
Cuando una de las dos ingresa el código de la otra, quedan vinculadas en un
**espacio de pareja** que solo ellas dos pueden ver.

## Qué trae esta primera versión

| Función | Estado |
| --- | --- |
| Registro e inicio de sesión (correo y contraseña, o Google) | ✅ |
| Pantallas de bienvenida (la primera vez) | ✅ |
| Vinculación por código de pareja | ✅ |
| Reglas de seguridad (solo la pareja ve sus datos) | ✅ con pruebas |
| Ánimo del día, visible para la pareja | ✅ (con emojis provisionales) |
| Mindfulness: respiración guiada, sugerida solo si el ánimo es estrés, tristeza, ansiedad, enojo, decepción, desánimo o mañas | ✅ |
| Pomodoro solo (enfoque y descanso, con tareas) | ✅ |
| Pomodoro en pareja: uno invita y el otro acepta | ✅ |
| Premios: al completar un pomodoro o una tarea eliges un premio de la lista de la pareja, y la otra persona lo ve y lo marca como entregado | ✅ |
| Contador de días juntos y próximo aniversario | ✅ |
| Notas compartidas + notas privadas que se pueden compartir | ✅ |
| Pregunta del día (ves la respuesta de tu pareja después de responder) | ✅ |
| Lista de cosas por hacer juntos | ✅ |
| Botón "Te extraño" con notificación push | ✅ (necesita el Worker gratis de Cloudflare, ver abajo) |

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (versión estable reciente)
- [Node.js](https://nodejs.org) 22 o más nuevo
- Una cuenta de Google para la [consola de Firebase](https://console.firebase.google.com)

## Configurar Firebase (una sola vez)

1. **Crea el proyecto.** En la [consola de Firebase](https://console.firebase.google.com)
   toca *Agregar proyecto* y ponle un nombre (por ejemplo `taotao`).
2. **Activa el inicio de sesión.** *Authentication → Comenzar → Correo
   electrónico/contraseña → Habilitar*.
3. **Crea la base de datos.** *Firestore Database → Crear base de datos*,
   elige una ubicación cercana (por ejemplo `southamerica-east1`) y modo
   producción.
4. **Instala las herramientas** en tu computadora:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```
5. **Conecta la app con tu proyecto.** Dentro de esta carpeta:
   ```bash
   flutterfire configure
   ```
   Elige tu proyecto y las plataformas (Android, iOS, web). Esto reemplaza
   `lib/firebase_options.dart` y crea los archivos de configuración
   (`google-services.json`, `GoogleService-Info.plist`).
6. **Sube las reglas de seguridad e índices:**
   ```bash
   firebase use --add          # elige tu proyecto
   firebase deploy --only firestore
   ```
7. **Corre la app:**
   ```bash
   flutter pub get
   flutter run
   ```

### Notificaciones push ("Te extraño", invitaciones de pomodoro y premios)

Todo Taotao funciona en el plan gratis **Spark** de Firebase. Las
notificaciones las envía un pequeño servidor gratis en **Cloudflare Workers**
(carpeta `worker/`), así no hace falta el plan Blaze ni tarjeta.

Cómo funciona: cuando tocas "Te extraño" (o invitas a un pomodoro, o eliges
un premio), la app guarda el documento en Firestore y le avisa al Worker. El
Worker comprueba quién eres con tu sesión de Firebase, revisa que el aviso
vaya para **tu pareja** y recién ahí manda la notificación. Nadie puede usarlo
para mandar avisos a otras personas.

Hazlo una sola vez, desde una terminal en la carpeta del proyecto:

1. **Crea tu cuenta de Cloudflare.** Entra a
   [dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up) y
   regístrate con tu correo. Es gratis y no pide tarjeta.
2. **Instala lo del Worker e inicia sesión:**
   ```bash
   cd worker
   npm install
   npx wrangler login
   ```
   Se abre el navegador; toca *Allow* para darle permiso a Wrangler (la
   herramienta de Cloudflare). Vuelve a la terminal cuando diga que ya está.
3. **Descarga la clave de la cuenta de servicio de Firebase.** En la
   [consola de Firebase](https://console.firebase.google.com) abre tu
   proyecto → ⚙️ *Configuración del proyecto* → pestaña *Cuentas de
   servicio* → *Generar nueva clave privada* → *Generar clave*. Se descarga
   un archivo `.json`.
   > 🔒 Ese archivo es como la llave maestra de tu base de datos. **No lo
   > pongas dentro de la carpeta del proyecto, no lo subas a GitHub y no lo
   > compartas con nadie** (ni lo pegues en un chat). Déjalo en Descargas.
4. **Guarda la clave como secreto del Worker.** Sigue dentro de `worker/` y
   cambia la ruta por la de tu archivo:
   - Mac o Linux:
     ```bash
     npx wrangler secret put FIREBASE_SERVICE_ACCOUNT < ~/Downloads/NOMBRE-DEL-ARCHIVO.json
     ```
   - Windows (PowerShell):
     ```powershell
     Get-Content "$HOME\Downloads\NOMBRE-DEL-ARCHIVO.json" -Raw | npx wrangler secret put FIREBASE_SERVICE_ACCOUNT
     ```
   Si te pregunta si quieres crear el Worker `taotao-notificaciones`, responde
   que sí (`Y`). Cuando diga *Success*, ya puedes **borrar el archivo `.json`**
   de Descargas: Cloudflare lo guardó cifrado.
5. **Publica el Worker:**
   ```bash
   npx wrangler deploy
   ```
   La primera vez te pide elegir un subdominio `workers.dev` (por ejemplo tu
   nombre). Al terminar muestra una dirección como
   `https://taotao-notificaciones.tu-nombre.workers.dev`. Ábrela en el
   navegador: si ves `{"ok":true,...}`, está funcionando.
6. **Pon esa dirección en la app.** Abre `lib/push_config.dart` y pégala
   entre las comillas, sin `/` al final:
   ```dart
   const notificationsUrl = 'https://taotao-notificaciones.tu-nombre.workers.dev';
   ```
   Luego `flutter pub get` y vuelve a correr la app en los dos teléfonos.
7. **Prueba:** inicia sesión con las dos cuentas en dos dispositivos y toca
   "Te extraño". Si no llega, mira qué pasa en el Worker con:
   ```bash
   cd worker && npx wrangler tail
   ```

El plan gratis de Cloudflare permite 100.000 pedidos por día, muchísimo más
de lo que usa una pareja. Si algún día cambias el código de `worker/`, vuelve
a correr `npx wrangler deploy`. Las pruebas del Worker se corren con
`cd worker && npm test`.

- **iOS:** en Xcode activa *Push Notifications* y *Background Modes → Remote
  notifications*, y sube tu clave APNs en *Configuración del proyecto →
  Cloud Messaging* de Firebase.
- **Web:** hace falta una clave VAPID y un `firebase-messaging-sw.js`; se puede
  agregar más adelante.

## Tus ilustraciones del login y la bienvenida

Las imágenes del inicio de sesión y de las 3 pantallas de bienvenida están en
`assets/images/`. Para poner tus propios dibujos, **reemplaza el archivo con
el mismo nombre** (PNG con fondo transparente, cuadrado, idealmente 800×800):

| Archivo | Dónde aparece |
| --- | --- |
| `login.png` | Arriba del "¡Hola de nuevo!" en el inicio de sesión |
| `onboarding_1.png` | Bienvenida, pantalla 1 (fondo azul) |
| `onboarding_2.png` | Bienvenida, pantalla 2 (fondo crema) |
| `onboarding_3.png` | Bienvenida, pantalla 3 (fondo azul) |

Después de cambiar una imagen, detén la app y vuelve a correr `flutter run`
(el *hot reload* no siempre recoge imágenes nuevas). Los textos de la
bienvenida están en `lib/screens/onboarding/onboarding_screen.dart` y los
colores en `lib/theme.dart`.

La bienvenida se muestra solo la primera vez. Para volver a verla en Chrome,
abre la app en una ventana de incógnito.

### Inicio de sesión con Google

El botón "G" del login usa el proveedor de Google de Firebase. Actívalo en
*Authentication → Sign-in method → Google*. En web funciona directo; para
Android hay que agregar la huella SHA-1 de tu app en *Configuración del
proyecto* de Firebase.

## Tus dibujos del ánimo

Guarda tus PNG (fondo transparente, cuadrados, idealmente 256×256) en
`assets/moods/` con estos nombres exactos:

| Archivo | Ánimo | ¿Sugiere mindfulness? |
| --- | --- | --- |
| `feliz.png` | Feliz | No |
| `ilusionado.png` | Con ilusión | No |
| `contento.png` | Contento | No |
| `en_paz.png` | En paz | No |
| `normal.png` | Normal | No |
| `cansado.png` | Cansado | No |
| `triste.png` | Triste | Sí |
| `ansioso.png` | Con ansiedad | Sí |
| `enojado.png` | Enojado | Sí |
| `decepcionado.png` | Decepcionado | Sí |
| `estresado.png` | Estresado | Sí |
| `con_sueno.png` | Con sueño | No |
| `sorprendido.png` | Sorprendido | No |
| `apagado.png` | Apagado | Sí |
| `manoso.png` | Mañoso | Sí |
| `empachado.png` | Empachado | No |

Mientras un archivo no exista, la app dibuja un bloblito de color con carita
en su lugar. Deja un poco de aire alrededor del dibujo: se muestra en un
cuadrado de unos 84 px en la cuadrícula y de 56 px en el inicio. Para cambiar
los textos, el orden o agregar ánimos, edita `lib/models/mood.dart`.

## El dibujo del pomodoro

La ilustración de arriba de la pantalla de Pomodoro es
`assets/images/pomodoro.png` (un tomatito provisional). Para usar tu propio
dibujo, reemplaza ese archivo con el mismo nombre: PNG con fondo
transparente, más ancho que alto (idealmente 900×560). La parte de abajo
del dibujo queda un poco escondida detrás de la tarjeta del temporizador,
así que deja el personaje más bien arriba y centrado. Los colores de esa
pantalla están en `lib/screens/pomodoro/pomodoro_style.dart`.

## Cómo está organizado

```
lib/
  main.dart            arranque y Firebase
  app.dart             decide: login → vincular pareja → inicio
  models/              datos (usuario, pareja, ánimo, notas, pomodoro…)
  services/            lectura/escritura en Firestore y notificaciones
  screens/             una carpeta por pantalla
  widgets/             piezas reutilizables
firestore.rules        reglas de seguridad
worker/                Worker de Cloudflare (envía las notificaciones push)
firestore-tests/       pruebas de las reglas con el emulador
```

### Datos en Firestore

```
users/{uid}                      nombre, código, coupleId, tokens de notificación
users/{uid}/privateNotes/{id}    notas privadas (solo su dueño)
users/{uid}/pomodoroTasks/{id}   tareas del pomodoro (solo su dueño)
pairCodes/{código}               código → uid
couples/{coupleId}               members (los dos uid), startDate
  moods/{uid}                    ánimo actual de cada uno
  notes/{id}                     notas compartidas
  pomodoros/{id}                 invitaciones y sesiones de pomodoro
  rewards/{id}                   lista de premios (la editan los dos)
  achievements/{id}              pomodoros y tareas cumplidas + premio elegido
  dailyAnswers/{aaaa-mm-dd}      respuestas a la pregunta del día
  bucketList/{id}                cosas por hacer juntos
  missYou/{id}                   "te extraño" (el Worker envía el aviso)
```

## Pruebas

```bash
flutter test                                # pruebas de la app
cd firestore-tests && npm install && npm test   # pruebas de las reglas (necesita Java)
cd worker && npm install && npm test           # pruebas del Worker de notificaciones
```
