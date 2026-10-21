#!/usr/bin/env bash
# Cacheable official Godot binaries and the single-threaded Safari-compatible template.
set -euo pipefail
cd "$(dirname "$0")/.."
version=4.6.3
release="https://github.com/godotengine/godot-builds/releases/download/${version}-stable"
mkdir -p .godot-tools godot-demo/.templates
if [[ -x .godot-tools/godot && -f godot-demo/.templates/web_nothreads_release.zip ]]; then
  exit 0
fi
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
if [[ ! -x .godot-tools/godot ]]; then
  curl -fL --retry 3 "${release}/Godot_v${version}-stable_linux.x86_64.zip" -o "$scratch/godot.zip"
  unzip -q "$scratch/godot.zip" -d "$scratch/bin"
  mv "$scratch/bin/Godot_v${version}-stable_linux.x86_64" .godot-tools/godot
  chmod +x .godot-tools/godot
fi
if [[ ! -f godot-demo/.templates/web_nothreads_release.zip ]]; then
  curl -fL --retry 3 "${release}/Godot_v${version}-stable_export_templates.tpz" -o "$scratch/templates.tpz"
  unzip -p "$scratch/templates.tpz" templates/web_nothreads_release.zip > godot-demo/.templates/web_nothreads_release.zip
fi
.godot-tools/godot --version
