#!/usr/bin/env bash
# 准备 Godot 引擎（Linux）：下载、解压、链接到 .engine/
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

useMono=0
versionNumber=4.8
flavor=dev3
engineDir=".engine"
tmpDir=".tmp"
cacheRoot="${GODOT_ENGINE_CACHE:-$HOME/.cache/godot-engines}"

if [[ "$useMono" != "0" ]]; then
  zipSlug="mono_linux_x86_64.zip"
  godotBin="Godot_v${versionNumber}-${flavor}_mono_linux.x86_64"
else
  zipSlug="linux.x86_64.zip"
  godotBin="Godot_v${versionNumber}-${flavor}_linux.x86_64"
fi

if [[ "$useMono" != "0" ]]; then
  cacheKey="${versionNumber}-${flavor}-mono"
else
  cacheKey="${versionNumber}-${flavor}-standard"
fi
cacheDir="${cacheRoot}/${cacheKey}"
engineBin="${engineDir}/${godotBin}"
linkPath="${engineDir}/.engine"
downloadUrl="https://downloads.godotengine.org/?version=${versionNumber}&flavor=${flavor}&slug=${zipSlug}&platform=linux.x86_64"

download() {
  local url="$1"
  local out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --http1.1 --retry 5 --retry-all-errors --retry-delay 2 -C - -o "$out" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$out" "$url"
  else
    echo "需要 curl 或 wget 才能下载引擎" >&2
    exit 1
  fi
}

ensure_link() {
  mkdir -p "$engineDir"
  if [[ ! -e "$engineBin" ]]; then
    echo "引擎二进制不存在: $engineBin" >&2
    exit 1
  fi
  chmod +x "$engineBin"
  # 优先硬链接，失败则回退为符号链接
  rm -f "$linkPath"
  if ln "$engineBin" "$linkPath" 2>/dev/null; then
    :
  else
    ln -sf "$(basename "$engineBin")" "$linkPath"
  fi
  chmod +x "$linkPath"
}

# 1. 项目内已有引擎则跳过下载
if [[ -x "$engineBin" ]]; then
  echo "Engine already exists, skipping download"
  ensure_link
  echo "Engine preparation completed!"
  exit 0
fi

# 2. 全局缓存命中则直接复用（便于 snapshot 后 install 更快）
if [[ -x "${cacheDir}/${godotBin}" ]]; then
  echo "Using cached engine at ${cacheDir}"
  rm -rf "$engineDir"
  mkdir -p "$engineDir"
  # 尽量硬链到缓存，跨文件系统时回退为复制
  if ln "${cacheDir}/${godotBin}" "$engineBin" 2>/dev/null; then
    # 同目录其它文件（若有）也一并链接/复制
    find "$cacheDir" -mindepth 1 -maxdepth 1 ! -name "$godotBin" -print0 \
      | while IFS= read -r -d '' item; do
          name="$(basename "$item")"
          ln "$item" "${engineDir}/${name}" 2>/dev/null || cp -a "$item" "${engineDir}/${name}"
        done
  else
    cp -a "${cacheDir}/." "$engineDir/"
  fi
  ensure_link
  echo "Engine preparation completed!"
  exit 0
fi

# 3. 下载并解压到缓存，再链到 .engine/
echo "Removing old engine folder (if any)..."
rm -rf "$engineDir"
mkdir -p "$tmpDir" "$cacheDir" "$engineDir"

zipFile="${tmpDir}/godot-${cacheKey}.zip"
extractDir="${tmpDir}/extract-${cacheKey}"
rm -rf "$extractDir"
mkdir -p "$extractDir"

echo "Downloading engine ${versionNumber}-${flavor}..."
download "$downloadUrl" "$zipFile"

echo "Extracting engine..."
unzip -qo "$zipFile" -d "$extractDir"

foundBin="$(find "$extractDir" -type f -name "$godotBin" | head -n 1 || true)"
if [[ -z "$foundBin" ]]; then
  echo "Engine binary not found in archive: $godotBin" >&2
  exit 1
fi

sourceDir="$(dirname "$foundBin")"
# 写入缓存
rm -rf "${cacheDir}.partial"
mkdir -p "${cacheDir}.partial"
cp -a "${sourceDir}/." "${cacheDir}.partial/"
chmod +x "${cacheDir}.partial/${godotBin}"
rm -rf "$cacheDir"
mv "${cacheDir}.partial" "$cacheDir"

# 链/复制到项目 .engine
if ln "${cacheDir}/${godotBin}" "$engineBin" 2>/dev/null; then
  find "$cacheDir" -mindepth 1 -maxdepth 1 ! -name "$godotBin" -print0 \
    | while IFS= read -r -d '' item; do
        name="$(basename "$item")"
        ln "$item" "${engineDir}/${name}" 2>/dev/null || cp -a "$item" "${engineDir}/${name}"
      done
else
  cp -a "${cacheDir}/." "$engineDir/"
fi

echo "Cleaning temp files..."
rm -rf "$tmpDir"

ensure_link
echo "Engine preparation completed!"
