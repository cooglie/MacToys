#!/bin/bash
#
# build.sh — Kompiliert MacToys (Universal Binary: arm64 + x86_64, macOS 13+)
# und baut das .app-Bundle inkl. Icon. Legt die fertige App auf den Desktop.
#
# Nutzung:  cd MacToys && bash build.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SRC="$ROOT/Sources"
BUILD="$ROOT/.build"
APP_BUNDLE="$BUILD/MacToys.app"
DEPLOY="12.0"

# Frameworks, die wir brauchen.
FRAMEWORKS="-framework AppKit -framework SwiftUI -framework Foundation -framework Combine -framework Carbon -framework ApplicationServices -framework CoreGraphics -framework ImageIO -framework ServiceManagement -framework Vision -framework Quartz -framework IOKit -framework UniformTypeIdentifiers"

echo "=== MacToys Build (Universal: arm64 + x86_64, macOS $DEPLOY+) ==="
echo "SDK: $SDK"
echo ""

mkdir -p "$BUILD"
rm -rf "$APP_BUNDLE"

# Swift-Quellen sammeln.
SOURCES=$(find "$SRC" -name '*.swift' | sort)
echo "Quellen:"
echo "$SOURCES" | sed 's/^/  /'
echo ""

# --- Icon vorab bauen (.icns) ---
build_icon() {
    local ICNS="$ROOT/Resources/AppIcon.icns"
    local ICONSET="$ROOT/Resources/icon.iconset"
    local SRC_IMG="$ROOT/Resources/icon-source.png"
    if [[ -f "$ICNS" ]]; then
        echo "🎨 Icon vorhanden: $ICNS"
        return
    fi
    if [[ ! -f "$SRC_IMG" ]]; then
        echo "🎨 Erzeuge Icon-Quelle via CoreGraphics (make_icon.swift) …"
        swift "$ROOT/make_icon.swift" "$SRC_IMG" || { echo "⚠️  Icon-Erzeugung fehlgeschlagen — überspringe."; return; }
    fi
    echo "🎨 Erzeuge .icns aus $SRC_IMG …"
    rm -rf "$ICONSET"; mkdir -p "$ICONSET"
    sips -z 16 16     "$SRC_IMG" --out "$ICONSET/icon_16x16.png"      >/dev/null
    sips -z 32 32     "$ICONSET/icon_16x16.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
    sips -z 32 32     "$SRC_IMG" --out "$ICONSET/icon_32x32.png"      >/dev/null
    sips -z 64 64     "$ICONSET/icon_32x32.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
    sips -z 128 128   "$SRC_IMG" --out "$ICONSET/icon_128x128.png"    >/dev/null
    sips -z 256 256   "$ICONSET/icon_128x128.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
    sips -z 256 256   "$SRC_IMG" --out "$ICONSET/icon_256x256.png"    >/dev/null
    sips -z 512 512   "$ICONSET/icon_256x256.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
    sips -z 512 512   "$SRC_IMG" --out "$ICONSET/icon_512x512.png"    >/dev/null
    sips -z 1024 1024 "$ICONSET/icon_512x512.png" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
    iconutil -c icns "$ICONSET" -o "$ICNS"
    rm -rf "$ICONSET"
    echo "✅ $ICNS"
}
build_icon

# --- Apple Silicon (arm64) ---
echo "Kompiliere arm64 (Apple Silicon)…"
swiftc -parse-as-library \
    -target arm64-apple-macosx$DEPLOY \
    -sdk "$SDK" -O \
    $FRAMEWORKS \
    $SOURCES \
    -o "$BUILD/MacToys.arm64"
echo "✅ arm64"

# --- Intel (x86_64) ---
echo "Kompiliere x86_64 (Intel)…"
swiftc -parse-as-library \
    -target x86_64-apple-macosx$DEPLOY \
    -sdk "$SDK" -O \
    $FRAMEWORKS \
    $SOURCES \
    -o "$BUILD/MacToys.x86_64"
echo "✅ x86_64"

# --- Universal Binary ---
echo "Füge zu Universal Binary zusammen (lipo)…"
lipo -create -output "$BUILD/MacToys" "$BUILD/MacToys.arm64" "$BUILD/MacToys.x86_64"
echo "✅ Universal:"
lipo -archs "$BUILD/MacToys"

# --- .app-Bundle ---
echo ""
echo "Baue .app-Bundle…"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BUILD/MacToys" "$APP_BUNDLE/Contents/MacOS/MacToys"
cp "$ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Quarantine-Flag entfernen + ad-hoc signieren.
xattr -d com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true
codesign --force --deep --sign - "$APP_BUNDLE"

# --- Auf den Desktop legen ---
DESKTOP="$HOME/Desktop"
TARGET="$DESKTOP/MacToys.app"
echo ""
echo "Lege App auf den Desktop…"
rm -rf "$TARGET"
cp -R "$APP_BUNDLE" "$TARGET"
xattr -d com.apple.quarantine "$TARGET" 2>/dev/null || true

echo ""
echo "✅ Fertig: $TARGET"
echo "   Architekturen: $(lipo -archs "$TARGET/Contents/MacOS/MacToys")"
echo ""
echo "Starten:  open \"$TARGET\""
echo ""
echo "ℹ️  Für den Window Manager: Systemeinstellungen → Datenschutz & Sicherheit → Bedienhilfen → MacToys aktivieren."
