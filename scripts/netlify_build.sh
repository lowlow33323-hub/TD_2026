#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.6.3}"
GODOT_TAG="${GODOT_TAG:-4.6.3-stable}"
GODOT_TEMPLATE_VERSION="${GODOT_VERSION}.stable"
GODOT_CACHE_DIR="${HOME}/.cache/godot-${GODOT_TAG}"
GODOT_BIN="${GODOT_CACHE_DIR}/Godot_v${GODOT_TAG}_linux.x86_64"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_TEMPLATE_VERSION}"

mkdir -p "${GODOT_CACHE_DIR}" "${TEMPLATE_DIR}" builds/web

if [ ! -x "${GODOT_BIN}" ]; then
  curl -L \
    "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_TAG}_linux.x86_64.zip" \
    -o /tmp/godot.zip
  unzip -q -o /tmp/godot.zip -d "${GODOT_CACHE_DIR}"
  chmod +x "${GODOT_BIN}"
fi

if [ ! -f "${TEMPLATE_DIR}/web_nothreads_release.zip" ]; then
  curl -L \
    "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_TAG}_export_templates.tpz" \
    -o /tmp/godot_templates.tpz
  rm -rf /tmp/godot_templates
  mkdir -p /tmp/godot_templates
  unzip -q -o /tmp/godot_templates.tpz -d /tmp/godot_templates
  cp /tmp/godot_templates/templates/web_nothreads_debug.zip "${TEMPLATE_DIR}/"
  cp /tmp/godot_templates/templates/web_nothreads_release.zip "${TEMPLATE_DIR}/"
fi

"${GODOT_BIN}" --headless --path . --import --quit
"${GODOT_BIN}" --headless --path . --export-release Web builds/web/index.html

hash_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

compress_asset() {
  local file="$1"
  gzip -kf -9 "${file}"
  if command -v brotli >/dev/null 2>&1; then
    brotli -f -q 6 "${file}"
  fi
}

ASSET_HASH="$(cat builds/web/index.js builds/web/index.wasm builds/web/index.pck | hash_stdin | cut -c 1-12)"
ASSET_BASE="td-${ASSET_HASH}"

mv builds/web/index.js "builds/web/${ASSET_BASE}.js"
mv builds/web/index.wasm "builds/web/${ASSET_BASE}.wasm"
mv builds/web/index.pck "builds/web/${ASSET_BASE}.pck"
mv builds/web/index.audio.worklet.js "builds/web/${ASSET_BASE}.audio.worklet.js"
mv builds/web/index.audio.position.worklet.js "builds/web/${ASSET_BASE}.audio.position.worklet.js"

python3 - "${ASSET_BASE}" <<'PY'
from pathlib import Path
import sys

base = sys.argv[1]
path = Path("builds/web/index.html")
html = path.read_text(encoding="utf-8")
for suffix in [
    "js",
    "wasm",
    "pck",
    "audio.worklet.js",
    "audio.position.worklet.js",
]:
    html = html.replace(f"index.{suffix}", f"{base}.{suffix}")
html = html.replace('"executable":"index"', f'"executable":"{base}"')
path.write_text(html, encoding="utf-8")
PY

for file in \
  "builds/web/${ASSET_BASE}.js" \
  "builds/web/${ASSET_BASE}.wasm" \
  "builds/web/${ASSET_BASE}.pck" \
  "builds/web/${ASSET_BASE}.audio.worklet.js" \
  "builds/web/${ASSET_BASE}.audio.position.worklet.js" \
  builds/web/index.html
do
  compress_asset "${file}"
done
