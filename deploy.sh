#!/bin/bash
# WowTracker Deploy Script — bouwt altijd correcte ZIP
# Gebruik: bash deploy.sh [versie]
# Output: WowTracker_vX.X.X.zip in huidige map

VERSION=${1:-"3.1.0"}
OUTPUT="WowTracker_v${VERSION}.zip"
TMPDIR=$(mktemp -d)
TARGET="$TMPDIR/WowTracker"

echo "[deploy] Bouwen WowTracker v$VERSION..."
mkdir -p "$TARGET"

# Kopieer alle addon bestanden
cp -r Core Media Plugins Docs "$TARGET/"
cp WowTracker.toc WowTracker.xml CHANGELOG.md README.md "$TARGET/" 2>/dev/null || true

# ZIP met WowTracker/ als root
cd "$TMPDIR"
zip -r "$OLDPWD/$OUTPUT" WowTracker/ --exclude "*.git*" -q

# Cleanup
rm -rf "$TMPDIR"

echo "[deploy] Klaar: $OUTPUT"
echo "[deploy] Inhoud:"
unzip -l "$OUTPUT" | grep -E "^\s+[0-9]" | head -20
