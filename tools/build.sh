#!/usr/bin/env bash
# Reproducible build for Echoes of the Last Dawn (Godot 4.7.2).
# Usage: tools/build.sh   (run from the project root)
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/workspace/tools/godot/Godot_v4.7.2-stable_linux.x86_64}"
if [ ! -x "$GODOT" ]; then
  echo "Godot 4.7.2 binary not found at $GODOT (set GODOT env var)"; exit 1
fi
echo "== import =="
"$GODOT" --headless --path . --import
echo "== tests =="
"$GODOT" --headless --path . -s tests/test_battle.gd
python3 tools/validate_content.py > /tmp/echoes_validate.log 2>&1 || { cat /tmp/echoes_validate.log; exit 1; }
echo "== exports =="
mkdir -p dist/web dist/linux
"$GODOT" --headless --path . --export-release "Web" dist/web/index.html
"$GODOT" --headless --path . --export-release "Linux" dist/linux/echoes-of-the-last-dawn.x86_64
chmod +x dist/linux/echoes-of-the-last-dawn.x86_64
python3 -c "
import sys
for p in ('dist/web/index.pck', 'dist/linux/echoes-of-the-last-dawn.pck'):
    assert open(p, 'rb').read(4) == b'GDPC', p + ' is not a Godot pack'
print('PCK magic OK (GDPC)')
"
echo "== packages =="
(cd dist/web && zip -q -r ../echoes-web.zip . -x "*/.DS_Store")
tar -czf dist/echoes-linux.tar.gz -C dist/linux .
(cd dist && sha256sum echoes-web.zip echoes-linux.tar.gz > SHA256SUMS)
ls -lh dist/
echo "BUILD OK"
