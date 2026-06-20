#!/bin/bash
set -e

if [ "$#" -ne 0 ]; then
  echo "Este script ya calcula el build automáticamente."
  echo "Uso: ./release_ios.sh"
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
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Current build: $CURRENT_BUILD"
echo "New build: $NEW_BUILD"
echo "Preparando Qibla Time $VERSION_NAME+$NEW_BUILD"

perl -0pi -e "s/^version:\s*\Q$VERSION_NAME\E\+\Q$CURRENT_BUILD\E\s*$/version: $VERSION_NAME+$NEW_BUILD/m" pubspec.yaml

flutter clean
flutter pub get
flutter analyze --no-fatal-infos
flutter build ipa --release || true

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

read -p "¿Subir cambios a GitHub? (y/n): " PUSH_GIT

if [ "$PUSH_GIT" = "y" ]; then
  git status
  read -p "Mensaje del commit: " COMMIT_MSG
  git add .
  git commit -m "$COMMIT_MSG"
  git push origin main
fi

read -p "¿Subir IPA a App Store Connect? (y/n): " UPLOAD_CONNECT

if [ "$UPLOAD_CONNECT" = "y" ]; then
  if [ -z "$APPLE_ID" ]; then
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
