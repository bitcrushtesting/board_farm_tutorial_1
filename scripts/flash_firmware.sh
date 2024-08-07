#!/bin/bash

# Copyright © 2024 Bitcrush Testing

BOARDS=("arduino:avr:uno" "arduino:renesas_uno:minima")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/../firmware/build"

if [ ! -e "$BUILD_DIR" ]; then
  echo "Build the firmware first"
  exit 1
fi

for BOARD in "${BOARDS[@]}"; do
    PORT=$(python3 ./find_board_port.py "$BOARD")
    echo "Flashing $BOARD on port $PORT"
    INPUT_DIR=$BUILD_DIR/$(echo "$BOARD" | tr ':' '.')
    arduino-cli upload -p "${PORT}" --fqbn "${BOARD}" --input-dir "${INPUT_DIR}" --verify --verbose
done

echo "-------- DONE ---------"
