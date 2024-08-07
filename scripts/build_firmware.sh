#!/bin/bash

# Copyright © 2024 Bitcrush Testing

VERSION="\"$(git describe --tags --abbrev=0)\""

if [ -z "$VERSION" ]; then
  echo "Error: VERSION is empty"
  exit 1
fi

GIT_HASH="\"$(git rev-parse --short HEAD)\""
BOARDS=("arduino:avr:uno" "arduino:renesas_uno:minima")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building firmware with version: ${VERSION} and git hash: ${GIT_HASH}"
arduino-cli lib install "ArduinoJson"
arduino-cli core install arduino:avr
arduino-cli core install arduino:renesas_uno

for BOARD in "${BOARDS[@]}"; do
    echo "Building $BOARD"
    arduino-cli compile --fqbn "${BOARD}" --build-property build.extra_flags="-DVERSION=${VERSION} -DGIT_HASH=${GIT_HASH}" "${SCRIPT_DIR}/../firmware" --export-binaries
done

echo "-------- DONE ---------"
