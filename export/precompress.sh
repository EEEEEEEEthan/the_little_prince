#!/usr/bin/env bash
# 将 Web 导出产物中的大文件原地 gzip，供 Cloudflare Pages（单文件 25MB 上限）托管。
# 旁车 *.gz / *.br 不入库；docs/ 内保留原文件名、内容为 gzip 字节。
set -euo pipefail

TARGET_DIR="${1:-docs}"
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "目录不存在: $TARGET_DIR" >&2
  exit 1
fi

compress_inplace() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local tmp="${file}.gztmp"
  gzip -9 -c "$file" > "$tmp"
  local original_size compressed_size
  original_size="$(wc -c < "$file")"
  compressed_size="$(wc -c < "$tmp")"
  if (( compressed_size >= original_size )); then
    rm -f "$tmp"
    echo "跳过（未变小）: $file"
    return 0
  fi
  mv "$tmp" "$file"
  echo "gzip: $file (${original_size} -> ${compressed_size})"
}

shopt -s nullglob
for pattern in wasm pck; do
  for file in "$TARGET_DIR"/*."$pattern"; do
    compress_inplace "$file"
  done
done

cat > "$TARGET_DIR/_headers" << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  X-Content-Type-Options: nosniff

/*.wasm
  Content-Type: application/wasm
  Content-Encoding: gzip
  Cache-Control: public, max-age=3600, no-transform

/*.pck
  Content-Type: application/octet-stream
  Content-Encoding: gzip
  Cache-Control: public, max-age=3600, no-transform
EOF

echo "已写入 $TARGET_DIR/_headers"
