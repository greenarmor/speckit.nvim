#!/usr/bin/env bash
set -euo pipefail

VERSION="2.3.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$ROOT_DIR/.cache/stylua"
BIN_PATH="$CACHE_DIR/stylua"

if [ -x "$BIN_PATH" ]; then
  exit 0
fi

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Linux) platform="linux" ;;
  Darwin) platform="macos" ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64|amd64) arch="x86_64" ;;
  arm64|aarch64)
    if [ "$platform" = "linux" ]; then
      arch="aarch64"
    else
      arch="arm64"
    fi
    ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

archive="stylua-${platform}-${arch}.zip"
url="https://github.com/JohnnyMorganz/StyLua/releases/download/v${VERSION}/${archive}"

mkdir -p "$CACHE_DIR"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -sSL "$url" -o "$tmpdir/stylua.zip"
unzip -q "$tmpdir/stylua.zip" -d "$tmpdir"
install -m 0755 "$tmpdir/stylua" "$BIN_PATH"
