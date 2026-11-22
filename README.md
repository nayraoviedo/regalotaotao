# Taotao 💞

App de pareja hecha en **Flutter** con **Firebase**.

Cada persona crea su cuenta y recibe un **código de pareja** de 6 letras.
Cuando una de las dos ingresa el código de la otra, quedan vinculadas en un
**espacio de pareja** que solo ellas dos pueden ver.

## Qué trae esta primera versión

| Función | Estado |
| --- | --- |
| Registro e inicio de sesión (correo y contraseña) | ✅ |
| Vinculación por código de pareja | ✅ |
| Reglas de seguridad (solo la pareja ve sus datos) | ✅ con pruebas |
| Ánimo del día, visible para la pareja | ✅ (con emojis provisionales) |
| Mindfulness: respiración guiada, sugerida solo si el ánimo es estrés, tristeza, ansiedad o enojo | ✅ |
| Pomodoro solo | ✅ |
| Pomodoro en pareja: uno invita y el otro acepta | ✅ |
| Contador de días juntos y próximo aniversario | ✅ |
| Notas compartidas + notas privadas que se pueden compartir | ✅ |
| Pregunta del día (ves la respuesta de tu pareja después de responder) | ✅ |
| Lista de cosas por hacer juntos | ✅ |
| Botón "Te extraño" con notificación push | ✅ (necesita desplegar las Cloud Functions) |

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

### Notificaciones push ("Te extraño" e invitaciones de pomodoro)

Las notificaciones las envían las Cloud Functions de la carpeta `functions/`.
Firebase pide el plan **Blaze** (pago por uso) para desplegar funciones; con
el uso de una pareja el costo normalmente es cero, pero conviene poner una
alerta de presupuesto.

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

- **iOS:** en Xcode activa *Push Notifications* y *Background Modes → Remote
  notifications*, y sube tu clave APNs en *Configuración del proyecto →
  Cloud Messaging* de Firebase.
- **Web:** hace falta una clave VAPID y un `firebase-messaging-sw.js`; se puede
  agregar más adelante.

## Tus dibujos del ánimo

Guarda tus PNG (fondo transparente, cuadrados, idealmente 256×256) en
`assets/moods/` con estos nombres exactos:

| Archivo | Ánimo | ¿Sugiere mindfulness? |
| --- | --- | --- |
| `feliz.png` | Feliz | No |
| `enamorado.png` | Con amor | No |
| `tranquilo.png` | En calma | No |
| `cansado.png` | Con sueño | No |
| `estresado.png` | Con estrés | Sí |
| `triste.png` | Triste | Sí |
| `ansioso.png` | Con ansiedad | Sí |
| `enojado.png` | Con enojo | Sí |

Mientras un archivo no exista, la app muestra un emoji en su lugar. Para
cambiar los nombres o agregar ánimos, edita `lib/models/mood.dart`.

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
functions/             Cloud Functions (notificaciones push)
firestore-tests/       pruebas de las reglas con el emulador
```

### Datos en Firestore

```
users/{uid}                      nombre, código, coupleId, tokens de notificación
users/{uid}/privateNotes/{id}    notas privadas (solo su dueño)
pairCodes/{código}               código → uid
couples/{coupleId}               members (los dos uid), startDate
  moods/{uid}                    ánimo actual de cada uno
  notes/{id}                     notas compartidas
  pomodoros/{id}                 invitaciones y sesiones de pomodoro
  dailyAnswers/{aaaa-mm-dd}      respuestas a la pregunta del día
  bucketList/{id}                cosas por hacer juntos
  missYou/{id}                   "te extraño" (dispara la notificación)
```

## Pruebas

```bash
flutter test                                # pruebas de la app
cd firestore-tests && npm install && npm test   # pruebas de las reglas (necesita Java)
```
