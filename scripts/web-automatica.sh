#!/usr/bin/env bash
# Deja lista la publicación AUTOMÁTICA de la web: después de esto, cada cambio
# que entra a main se publica solo en https://<tu-proyecto>.web.app (lo hace
# .github/workflows/web.yml). Córrelo UNA vez desde la carpeta del repo:
#
#     bash scripts/web-automatica.sh
#
# Qué hace: usa `firebase init hosting:github`, que crea una cuenta de servicio
# que solo puede publicar la web y la guarda en GitHub como el secret
# FIREBASE_SERVICE_ACCOUNT_<PROYECTO>. Lo corre en una carpeta temporal para
# que no toque los archivos del repo.
#
# Necesita: firebase (con `firebase login` hecho) y poder entrar a GitHub en el
# navegador con la cuenta dueña del repo.
set -euo pipefail

REPO="${REPO:-nayraoviedo/regalotaotao}"
command -v firebase >/dev/null || { echo "❌ Falta el comando 'firebase'."; exit 1; }

OPCIONES="lib/firebase_options.dart"
PROYECTO="${PROYECTO:-$(grep -o "projectId: '[^']*'" "$OPCIONES" 2>/dev/null | head -1 | cut -d"'" -f2 || true)}"
PROYECTO="${PROYECTO:-taotao-bd5ee}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp firebase.json .firebaserc "$TMP/"

cat <<MSG
Proyecto de Firebase: $PROYECTO
Repositorio:          $REPO

Firebase te va a hacer unas preguntas. Responde así:
  • "Are you ready to proceed?"                         → Y
  • Si se abre GitHub en el navegador                   → autoriza a Firebase CLI
  • "For which GitHub repository…"                      → $REPO
  • "Set up the workflow to run a build script…"        → n
  • "Set up automatic deployment … when a PR is merged" → n
  (Esos workflows no hacen falta: el repo ya trae .github/workflows/web.yml.)

MSG
read -r -p "Presiona Enter para empezar…" _

( cd "$TMP" && firebase init hosting:github --project "$PROYECTO" )

SECRETO="FIREBASE_SERVICE_ACCOUNT_$(echo "$PROYECTO" | tr '[:lower:]-' '[:upper:]_')"
echo
echo "✅ Listo. En GitHub debe aparecer el secret $SECRETO"
echo "   (repo → Settings → Secrets and variables → Actions)."
if command -v gh >/dev/null; then
  gh secret list --repo "$REPO" | grep -q "^$SECRETO" \
    && echo "   Lo comprobé con gh: ya está. ✨" \
    || echo "   ⚠️  gh no lo ve todavía. Revisa la página de secrets."
fi
echo "   Para publicar ahora mismo: GitHub → Actions → \"Web\" → Run workflow."
