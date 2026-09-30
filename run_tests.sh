#!/usr/bin/env bash
# Runs the whole GUT suite headless. Usage: ./run_tests.sh [extra gut args]
# Set GODOT to your Godot 4.7 executable if it is not the default Steam path.
GODOT="${GODOT:-/d/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
cd "$(dirname "$0")"
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "$@"
