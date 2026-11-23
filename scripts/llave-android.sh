#!/usr/bin/env bash
# Deja lista la firma fija del APK de prueba para que "Entrar con Google"
# funcione en el celular. Córrelo una vez en tu compu, desde la carpeta del
# repo:
#
#     bash scripts/llave-android.sh
#
# Qué hace:
#   1. Crea una llave de firma en ~/.taotao/debug.keystore (si ya existe, la
#      reusa). NO la subas al repo.
#   2. La guarda en GitHub como el secret ANDROID_DEBUG_KEYSTORE (con gh), así
#      todos los APK de GitHub salen firmados con la misma llave.
#   3. Registra sus huellas SHA-1 y SHA-256 en tu app Android de Firebase
#      (con firebase CLI). Sin eso, Google responde "invalid-cert-hash".
#
# Necesita: openssl, gh (con `gh auth login` hecho) y firebase
# (con `firebase login` hecho). No necesita Java ni Android Studio.
set -euo pipefail

REPO="${REPO:-nayraoviedo/regalotaotao}"
DIR="$HOME/.taotao"
LLAVE="$DIR/debug.keystore"
CERT="$DIR/debug-cert.pem"

for cmd in openssl gh firebase; do
  command -v "$cmd" >/dev/null || { echo "❌ Falta el comando '$cmd'."; exit 1; }
done

# Proyecto y app Android: se leen de tu lib/firebase_options.dart real.
OPCIONES="lib/firebase_options.dart"
PROYECTO="${PROYECTO:-$(grep -o "projectId: '[^']*'" "$OPCIONES" 2>/dev/null | head -1 | cut -d"'" -f2 || true)}"
PROYECTO="${PROYECTO:-taotao-bd5ee}"
APP_ID="${APP_ID:-$(grep -o "'[0-9]*:[0-9]*:android:[0-9a-f]*'" "$OPCIONES" 2>/dev/null | head -1 | tr -d "'" || true)}"
if [ -z "$APP_ID" ]; then
  echo "❌ No encontré el appId de Android en $OPCIONES."
  echo "   Búscalo con: firebase apps:list ANDROID --project $PROYECTO"
  echo "   y vuelve a correr: APP_ID=<el appId> bash scripts/llave-android.sh"
  exit 1
fi
echo "Proyecto de Firebase: $PROYECTO"
echo "App Android:          $APP_ID"

# 1. La llave (alias y contraseñas iguales a las de una llave debug normal).
mkdir -p "$DIR"
chmod 700 "$DIR"
if [ ! -f "$LLAVE" ]; then
  echo "🔑 Creando la llave en $LLAVE…"
  openssl req -x509 -newkey rsa:2048 -nodes -days 10000 \
    -subj "/CN=Android Debug/O=Android/C=US" \
    -keyout "$DIR/debug-key.pem" -out "$CERT" 2>/dev/null
  openssl pkcs12 -export -name androiddebugkey \
    -inkey "$DIR/debug-key.pem" -in "$CERT" \
    -passout pass:android -out "$LLAVE"
  rm -f "$DIR/debug-key.pem"
  chmod 600 "$LLAVE"
else
  echo "🔑 Ya tenías la llave en $LLAVE, la reuso."
  openssl pkcs12 -in "$LLAVE" -passin pass:android -nokeys -clcerts 2>/dev/null \
    | openssl x509 -out "$CERT"
fi

SHA1=$(openssl x509 -in "$CERT" -noout -fingerprint -sha1 | cut -d= -f2)
SHA256=$(openssl x509 -in "$CERT" -noout -fingerprint -sha256 | cut -d= -f2)
echo "SHA-1:   $SHA1"
echo "SHA-256: $SHA256"

# 2. El secret en GitHub.
echo "⬆️  Guardando el secret ANDROID_DEBUG_KEYSTORE en $REPO…"
base64 -w0 "$LLAVE" | gh secret set ANDROID_DEBUG_KEYSTORE -R "$REPO"

# 3. Las huellas en Firebase (si ya estaban, Firebase avisa y seguimos).
for sha in "$SHA1" "$SHA256"; do
  limpio=$(echo "$sha" | tr -d ':' | tr 'A-F' 'a-f')
  echo "📝 Registrando $sha en Firebase…"
  firebase apps:android:sha:create "$APP_ID" "$limpio" --project "$PROYECTO" \
    || echo "   (no se pudo; si dice que ya existe, está bien)"
done

echo
echo "✅ Listo. Ahora:"
echo "   1. En GitHub: Actions → 'APK de prueba' → Run workflow (rama main)."
echo "   2. En el celular desinstala Taotao una vez (la firma cambió) e instala"
echo "      el APK nuevo de Releases. Los siguientes se instalan encima."
