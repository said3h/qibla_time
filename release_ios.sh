#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

IOS_BUILD_OVERRIDE=""
if [ "$#" -eq 2 ] && [ "$1" = "--build-number" ] && [[ "$2" =~ ^[1-9][0-9]*$ ]]; then
  IOS_BUILD_OVERRIDE="$2"
elif [ "$#" -ne 0 ]; then
  echo "Uso: ./release_ios.sh [--build-number NUMERO]"
  echo "Sin argumentos, el build se incrementa automáticamente."
  exit 1
fi

CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD)" || {
  echo "ERROR: El repositorio está en detached HEAD. Selecciona una rama antes de publicar."
  exit 1
}
if [ -n "$(git ls-files -u)" ]; then
  echo "ERROR: Hay conflictos Git pendientes. Resuélvelos antes de publicar."
  exit 1
fi

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
elif [ -x "/Users/said3h/development/flutter/bin/flutter" ]; then
  FLUTTER_BIN="/Users/said3h/development/flutter/bin/flutter"
else
  echo "No se encontró Flutter."
  echo "Añade Flutter al PATH o instala Flutter en /Users/said3h/development/flutter."
  exit 1
fi

if [ -z "${GEOAPIFY_API_KEY:-}" ]; then
  echo ""
  echo "ERROR: GEOAPIFY_API_KEY no está configurada."
  echo "Ejecuta antes:"
  echo 'read -s "GEOAPIFY_API_KEY?Geoapify API key: "; export GEOAPIFY_API_KEY'
  exit 1
fi

VERSION_LINE="$(grep -E '^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+[[:space:]]*$' pubspec.yaml | head -n 1 || true)"

if [ -z "$VERSION_LINE" ]; then
  echo "No se pudo encontrar una línea de versión válida en pubspec.yaml."
  echo "Formato esperado: version: 1.6.0+25"
  exit 1
fi

VERSION_NAME="$(echo "$VERSION_LINE" | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)\+[0-9]+[[:space:]]*$/\1/')"
CURRENT_BUILD="$(echo "$VERSION_LINE" | sed -E 's/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)[[:space:]]*$/\1/')"
if [ -n "$IOS_BUILD_OVERRIDE" ]; then
  NEW_BUILD="$IOS_BUILD_OVERRIDE"
  echo "Build específico de iOS: $NEW_BUILD (contador Android conservado: $CURRENT_BUILD)"
else
  NEW_BUILD=$((CURRENT_BUILD + 1))
fi

echo "Current build: $CURRENT_BUILD"
echo "New build: $NEW_BUILD"
echo "Preparando Qibla Time $VERSION_NAME+$NEW_BUILD"

if [ -z "$IOS_BUILD_OVERRIDE" ]; then
  perl -0pi -e "s/^version:\s*\Q$VERSION_NAME\E\+\Q$CURRENT_BUILD\E\s*$/version: $VERSION_NAME+$NEW_BUILD/m" pubspec.yaml
fi

"$FLUTTER_BIN" clean
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" analyze --no-fatal-infos
"$FLUTTER_BIN" test --no-pub

if ! security find-identity -v -p codesigning | grep -qE '[0-9]+\) [A-F0-9]{40}'; then
  echo ""
  echo "ERROR: No hay certificados de firma iOS válidos en este Mac."
  echo "Abre Xcode, inicia sesión con tu Apple ID y crea/descarga un certificado válido para el Team ID 4XJTFN47FF."
  echo "Después vuelve a ejecutar ./release_ios.sh"
  exit 1
fi

"$FLUTTER_BIN" build ipa --release \
  --build-number="$NEW_BUILD" \
  --dart-define=GEOAPIFY_API_KEY="$GEOAPIFY_API_KEY"

if [ ! -d "build/ios/archive/Runner.xcarchive" ]; then
  echo ""
  echo "ERROR: No se creó el archive iOS en build/ios/archive/Runner.xcarchive."
  echo "Revisa el error de firma/build anterior antes de exportar el IPA."
  exit 1
fi

cat > /tmp/qibla_export_options.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>4XJTFN47FF</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

rm -rf build/ios/ipa_manual

xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa_manual \
  -exportOptionsPlist /tmp/qibla_export_options.plist

echo ""
echo "IPA creada en:"
echo "build/ios/ipa_manual/QiblaTime.ipa"
echo ""

read -r -p "¿Subir cambios a GitHub? (y/n): " PUSH_GIT

if [ "$PUSH_GIT" = "y" ]; then
  git status --short
  echo "Rama actual: $CURRENT_BRANCH"
  echo "Solo se incluirán los archivos preparados en Git (staged)."
  echo "Puedes añadir archivos escribiendo una ruta exacta cada vez."
  echo "Pulsa Enter sin escribir nada para terminar la selección."
  while true; do
    read -r -p "Archivo para incluir: " FILE_TO_STAGE
    [ -z "$FILE_TO_STAGE" ] && break
    if [ -d "$FILE_TO_STAGE" ]; then
      echo "Introduce un archivo concreto, no una carpeta."
      continue
    fi
    if ! git --literal-pathspecs add -- "$FILE_TO_STAGE"; then
      echo "No se pudo preparar ese archivo. Revisa la ruta."
    fi
  done

  if ! git diff --cached --quiet; then
    git diff --cached --check
    git diff --cached --stat
    git diff --cached --name-status
    read -r -p "¿Confirmas el commit de estos archivos? (y/n): " CONFIRM_COMMIT
    if [ "$CONFIRM_COMMIT" = "y" ]; then
      read -r -p "Mensaje del commit: " COMMIT_MSG
      if [[ ! "$COMMIT_MSG" =~ [^[:space:]] ]]; then
        echo "ERROR: El mensaje del commit no puede estar vacío."
        exit 1
      fi
      git commit -m "$COMMIT_MSG"
    fi
  fi

  read -r -p "Rama de destino en origin [$CURRENT_BRANCH]: " TARGET_BRANCH
  TARGET_BRANCH="${TARGET_BRANCH:-$CURRENT_BRANCH}"
  git check-ref-format "refs/heads/$TARGET_BRANCH" || {
    echo "ERROR: Nombre de rama de destino inválido."
    exit 1
  }
  echo "Se subirán los commits de $CURRENT_BRANCH a origin/$TARGET_BRANCH."
  echo "Los cambios sin commit no se subirán."
  read -r -p "¿Confirmas este push? (y/n): " CONFIRM_PUSH
  if [ "$CONFIRM_PUSH" = "y" ]; then
    git push origin "HEAD:refs/heads/$TARGET_BRANCH"
  fi
fi

read -r -p "¿Subir IPA a App Store Connect? (y/n): " UPLOAD_CONNECT

if [ "$UPLOAD_CONNECT" = "y" ]; then
  if [ -z "${APPLE_ID:-}" ]; then
    echo ""
    echo "ERROR: APPLE_ID no está configurado."
    echo "Añade esta línea a ~/.zshrc:"
    echo 'export APPLE_ID="tu_correo@ejemplo.com"'
    exit 1
  fi

  xcrun altool --upload-app \
    --type ios \
    --file "build/ios/ipa_manual/QiblaTime.ipa" \
    --username "$APPLE_ID"
fi

echo "Proceso terminado."
