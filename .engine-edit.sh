#!/usr/bin/env bash
# 准备引擎并打开 Godot 编辑器（Linux/macOS）
set -euo pipefail
bash "$(dirname "${BASH_SOURCE[0]}")/.engine-prepare.sh"
exec "$(dirname "${BASH_SOURCE[0]}")/.engine/.engine" --editor --path .
