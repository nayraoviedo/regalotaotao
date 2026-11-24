# 星月 💞

_你是我的星的月 · tú eres la estrella de mi luna_ (antes "Taotao")

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
| Recomendación del día (canción, playlist, peli, lugar…) con reproductor de Spotify/YouTube, reseñas con estrellitas e historial | ✅ |
| Versión web en https://taotao-bd5ee.web.app (Firebase Hosting gratis) | ✅ |

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
- **Web:** funciona en la web publicada (ver "Taotao en la web"), gracias a
  `web/firebase-messaging-sw.js`. No hace falta clave VAPID propia.

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

### Su gatito triste y el abrazo

Cuando tu pareja registra un ánimo que sugiere mindfulness (la columna "Sí"
de arriba), en tu inicio aparece su gatito triste con el botón **Mandar un
abrazo**, que le llega como notificación. El dibujo se cambia reemplazando
`assets/images/animo_triste_naranja.png` y `animo_triste_blanco.png`
(cuadrados, fondo transparente, 600×600). Los originales editables están en
`assets/dibujos_editables/`. Para que llegue la notificación del abrazo,
vuelve a publicar el Worker (`cd worker && npx wrangler deploy`).

## El dibujo del pomodoro

La ilustración de arriba de la pantalla de Pomodoro es
`assets/images/pomodoro.png` (un tomatito provisional). Para usar tu propio
dibujo, reemplaza ese archivo con el mismo nombre: PNG con fondo
transparente, más ancho que alto (idealmente 900×560). La parte de abajo
del dibujo queda un poco escondida detrás de la tarjeta del temporizador,
así que deja el personaje más bien arriba y centrado. Los colores de esa
pantalla están en `lib/screens/pomodoro/pomodoro_style.dart`.

### El maullido al terminar

Cuando termina un pomodoro (solo, el descanso o la sesión juntos) suena
`assets/sonidos/raw/maullido.mp3`. En Android, si la app está en segundo
plano o con la pantalla apagada, llega una notificación con ese mismo
maullido. Para usar otro sonido, reemplaza ese archivo con el **mismo
nombre** (mp3 corto, de 1 a 2 segundos). El que viene ahora es un maullido
provisional hecho con `assets/dibujos_editables/generar_maullido.py`.

## Cartas "Ábrelo cuando…" y el papel de las notas

En **Notas → Cartas** cada uno le escribe cartas a su pareja para un momento
("cuando estés triste", "cuando me extrañes"…). Llegan con un avioncito de
papel y se ven como sobres con sello; por dentro, las cartas y las notas se
ven como papel crema con cuadrícula o renglones celestes y destellos.

Todos los dibujos son opcionales y se cambian poniendo un PNG con fondo
transparente en `assets/images/` con estos nombres (si no existen, la app
dibuja uno simple):

| Archivo | Dónde aparece |
|---|---|
| `avioncito.png` | El avioncito que llega volando (600×400, mirando a la derecha) |
| `sello.png` | El sello de todos los sobres (300×300, redondo) |
| `sello_triste.png`, `sello_extranes.png`, … | Sello para un motivo en especial (ver `lib/screens/notes/cartas/cartas_style.dart`) |
| `papel_arriba.png` | Dibujito en la esquina de arriba de la hoja (300×300) |
| `papel_abajo.png` | Dibujito en la esquina de abajo de la hoja (300×300) |

Para que también llegue la notificación push de carta nueva, vuelve a
publicar el Worker (`cd worker && npx wrangler deploy`).

## Widget del celular (solo Android)

Un widget de 4×2 para la pantalla de inicio con los **días juntos** y el
**ánimo de tu pareja**, con los gatitos y en crema y azul marino. Al tocarlo
se abre la app. En web (Brave) no existe, así que no se ve ahí.

- Usa los mismos dibujos de la app (gatitos y ánimos, también tus PNG de
  `assets/`): la app los exporta al widget cada vez que la abres.
- Los días los cuenta el propio widget, así el número cambia solo cada día.
- El ánimo se actualiza al instante con la app abierta y, con la app cerrada,
  más o menos cada 30 minutos (tarea en segundo plano, gratis, sin Blaze).

Para probarlo, con el celular Android conectado por USB (depuración USB activa):

```bash
flutter run -d android
```

Abre la app una vez con tu cuenta, luego mantén apretado un espacio vacío de
la pantalla de inicio → **Widgets** → **Taotao** y arrástralo.
El diseño está en `android/app/src/main/res/layout/taotao_widget.xml` y la
lógica en `TaotaoWidget.kt` y `lib/services/widget_celular/`.

## Probar en el celular sin SDK de Android (APK desde GitHub)

No hace falta instalar Android Studio ni el SDK: GitHub arma el APK en la
nube con el archivo `.github/workflows/apk.yml`. Se arma solo en cada PR y en
cada cambio que entra a `main`, y también puedes pedirlo a mano.

### 1. Poner tu configuración de Firebase en GitHub (una sola vez)

Tu `lib/firebase_options.dart` real no está subido al repo, así que GitHub
no lo tiene. Se lo das como un *secret* (queda guardado y nadie lo ve):

1. En tu compu, abre `lib/firebase_options.dart` (el que creó
   `flutterfire configure`) y copia **todo** su texto.
2. En GitHub, entra al repo → **Settings** → **Secrets and variables** →
   **Actions** → **New repository secret**.
3. En *Name* escribe `FIREBASE_OPTIONS_DART` y en *Secret* pega el texto.
   Toca **Add secret**.
4. (Opcional) Si tienes `android/app/google-services.json`, haz lo mismo con
   el nombre `GOOGLE_SERVICES_JSON`.

Sin el secret el APK igual se arma, pero al abrir la app te dirá que falta
configurar Firebase.

### 1b. Para que "Entrar con Google" funcione en el APK (una sola vez)

Google solo deja entrar desde un APK cuya firma (huella SHA-1/SHA-256) esté
registrada en Firebase; si no, sale *"Ocurrió un error (invalid-cert-hash)"*.
Para que la firma de GitHub sea siempre la misma, corre en tu compu, dentro
de la carpeta del repo (necesitas `gh` y `firebase` con sesión iniciada):

```bash
bash scripts/llave-android.sh
```

El script crea la llave en `~/.taotao/debug.keystore` (no la subas al repo),
la guarda en GitHub como el secret `ANDROID_DEBUG_KEYSTORE` y registra sus
huellas en tu app Android de Firebase. Después pide un APK nuevo (paso 2),
desinstala Taotao del celular **una vez** (la firma cambió) e instálalo.

Cada corrida muestra las huellas que usó en su resumen (pestaña Actions →
la corrida → *Summary*), por si quieres compararlas con las de Firebase
(**Configuración del proyecto** → tu app Android → *Huellas digitales del
certificado SHA*).

### 2. Descargar el APK

- **Lo último de `main`:** en el repo, pestaña **Releases** → *APK de prueba
  (último main)* → toca `taotao.apk`. Es lo más fácil desde el celular.
- **El de un PR o una corrida a mano:** pestaña **Actions** → elige la
  corrida *APK de prueba* (con ✅) → abajo, en **Artifacts**, descarga el
  archivo. Viene en un `.zip`: ábrelo con la app *Archivos* del celular y
  toca el `.apk` de adentro.
- **Pedirlo a mano:** **Actions** → *APK de prueba* → **Run workflow** →
  elige la rama → **Run workflow**. Tarda unos 10 minutos.

### 3. Instalarlo

1. Toca el `.apk` descargado. Si el celular pregunta, permite *Instalar apps
   desconocidas* para el navegador o *Archivos*.
2. Si dice *"App no instalada"*, desinstala Taotao primero (pasa si antes la
   instalaste con `flutter run` desde tu compu, porque la firma es otra) y
   vuelve a tocar el `.apk`. Los siguientes APK de GitHub se instalan encima.
3. Abre la app, entra con tu cuenta, y luego agrega los widgets: mantén
   apretado un espacio vacío de la pantalla de inicio → **Widgets** →
   **Taotao** (días juntos y ánimo) o **Casita**.

## Taotao en la web (gratis, con Firebase Hosting)

La app también se puede abrir desde cualquier navegador (compu o celular) en
**https://taotao-bd5ee.web.app**. Usa Firebase Hosting, que es gratis en el
plan Spark. Es la misma app y los mismos datos: lo que hagas en la web lo ve
tu pareja en el celular, y al revés.

### Publicarla desde tu compu (lo más rápido)

Desde la carpeta del repo, con tu `lib/firebase_options.dart` real (debe
incluir la plataforma **web**):

```bash
bash scripts/publicar-web.sh
```

Arma la web y la sube. Vuelve a correrlo cada vez que quieras subir cambios.

### Que se publique sola con cada cambio en `main` (una sola vez)

```bash
bash scripts/web-automatica.sh
```

El script te dice qué responder. Crea una cuenta de servicio que **solo**
puede publicar la web y la guarda en GitHub como el secret
`FIREBASE_SERVICE_ACCOUNT_TAOTAO_BD5EE`. Desde ahí, el workflow
`.github/workflows/web.yml` publica la web en cada push a `main` (o a mano:
**Actions** → *Web* → **Run workflow**). Usa el mismo secret
`FIREBASE_OPTIONS_DART` del APK. Si falta algún secret, la web se arma pero no
se publica, para no reemplazar la buena.

### Qué cambia en la web

- **Entrar con correo o con Google:** funcionan igual. Firebase autoriza solo
  los dominios `taotao-bd5ee.web.app` y `taotao-bd5ee.firebaseapp.com`
  (míralo en *Authentication* → *Settings* → *Authorized domains*). Si algún
  día usas otra dirección, agrégala ahí o Google dirá `unauthorized-domain`.
- **Notificaciones push:** llegan al navegador aunque la pestaña esté cerrada
  (las manda el mismo Worker). La primera vez el navegador pregunta si las
  permites: di que sí.
  - **Brave:** activa *Usar los servicios de Google para mensajes push* en
    `brave://settings/privacy` y reinicia Brave.
  - **iPhone:** solo funcionan si agregas la web a la pantalla de inicio
    (Safari → Compartir → *Agregar a inicio*, iOS 16.4 o más nuevo) y la abres
    desde ese ícono.
  - Con `flutter run -d web-server` en tu compu no hay push web; solo en la
    dirección publicada.
- **Instalarla como app:** en Chrome, Edge o Brave aparece *Instalar* en la
  barra de direcciones; en el celular, *Agregar a la pantalla de inicio*.
- **Solo en Android:** los widgets del celular y el maullido con la pantalla
  apagada. En la web, "Bloquear pantalla" del pomodoro pone pantalla completa
  (se sale con Esc).

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
  abrazos/{id}                   abrazos cuando su ánimo no anda bien (también con aviso)
```

## Pruebas

```bash
flutter test                                # pruebas de la app
cd firestore-tests && npm install && npm test   # pruebas de las reglas (necesita Java)
cd worker && npm install && npm test           # pruebas del Worker de notificaciones
```

## Nombre e ícono

El nombre visible es **星月** (xīngyuè, "estrella y luna", de "你是我的星的月"; en `lib/branding.dart`, `AndroidManifest.xml`,
`web/index.html`, `web/manifest.json` e `ios/Runner/Info.plist`). El paquete
sigue siendo `com.taotao.taotao` para no romper Firebase ni el login con Google.

Para cambiar el ícono por tu dibujo, reemplaza los PNG de
`assets/dibujos_editables/icono/` (`icono_app.png` con fondo,
`icono_app_frente.png` sin fondo, `icono_notificacion.png` silueta) y corre:

    python3 assets/dibujos_editables/icono/generar_iconos.py
