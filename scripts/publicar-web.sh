#!/usr/bin/env bash
# Publica Taotao en la web (Firebase Hosting, gratis en el plan Spark) desde
# tu compu. Córrelo desde la carpeta del repo cada vez que quieras subir la
# versión que tienes:
#
#     bash scripts/publicar-web.sh
#
# Queda en https://<tu-proyecto>.web.app (por ejemplo https://taotao-bd5ee.web.app).
#
# Necesita: flutter y firebase (con `firebase login` hecho), y tu
# lib/firebase_options.dart real (el que creó `flutterfire configure`).
set -euo pipefail

for cmd in flutter firebase; do
  command -v "$cmd" >/dev/null || { echo "❌ Falta el comando '$cmd'."; exit 1; }
done

OPCIONES="lib/firebase_options.dart"
if grep -q "ARCHIVO PROVISIONAL" "$OPCIONES"; then
  echo "❌ $OPCIONES es el provisional. Corre 'flutterfire configure' primero."
  exit 1
fi
if ! grep -q "static const FirebaseOptions web" "$OPCIONES"; then
  echo "❌ $OPCIONES no tiene la configuración web."
  echo "   Corre 'flutterfire configure' y marca también la plataforma web."
  exit 1
fi
PROYECTO="${PROYECTO:-$(grep -o "projectId: '[^']*'" "$OPCIONES" | head -1 | cut -d"'" -f2)}"
echo "Proyecto de Firebase: $PROYECTO"

echo "🛠️  Armando la versión web…"
flutter pub get
flutter build web --release

echo "🚀 Subiendo a Firebase Hosting…"
firebase deploy --only hosting --project "$PROYECTO"

echo
echo "✅ Listo: https://$PROYECTO.web.app"
echo "   Si alguien ya la tenía abierta, que recargue la página."
