#!/bin/zsh
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/RARParts.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc "$ROOT/RARPartsApp.swift" -o "$APP/Contents/MacOS/RARParts"
cp /opt/homebrew/Cellar/unar/1.10.8_7/bin/unar "$APP/Contents/Resources/unar"
chmod +x "$APP/Contents/MacOS/RARParts" "$APP/Contents/Resources/unar"
cp /opt/homebrew/Cellar/unar/1.10.8_7/LICENSE "$APP/Contents/Resources/UNAR-LICENSE"
cp /opt/homebrew/Cellar/unar/1.10.8_7/README.md "$APP/Contents/Resources/UNAR-README.md"
cp "$ROOT/RARParts-Info.plist" "$APP/Contents/Info.plist"
echo "Built $APP"
