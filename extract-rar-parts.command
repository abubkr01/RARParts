#!/bin/zsh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ $# -eq 0 ]]; then
  echo "Drag the .part1.rar file onto this app, or run:"
  echo "  $0 /path/to/archive.part1.rar"
  exit 1
fi
exec python3 "$SCRIPT_DIR/rar_parts_extract.py" "$@"
