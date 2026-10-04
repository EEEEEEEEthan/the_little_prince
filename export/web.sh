#!/usr/bin/env bash
# 导出 Web 包到 docs/，并做 Cloudflare Pages 所需的 gzip 原地压缩。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENGINE="${ENGINE:-.engine/.engine}"
OUT_DIR="docs"
BUILD_DIR="build/web"

if [[ ! -x "$ENGINE" ]]; then
  echo "引擎不存在，先运行 bash .engine-prepare.sh" >&2
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

echo "导出 Web release..."
"$ENGINE" --headless --path . --export-release "Web" "$BUILD_DIR/index.html"

echo "同步到 $OUT_DIR ..."
rm -rf "${OUT_DIR:?}/"*
cp -a "$BUILD_DIR"/. "$OUT_DIR"/

bash export/precompress.sh "$OUT_DIR"

echo "Web 包就绪: $OUT_DIR"
ls -lh "$OUT_DIR"
