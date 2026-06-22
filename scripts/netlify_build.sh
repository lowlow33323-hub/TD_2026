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
