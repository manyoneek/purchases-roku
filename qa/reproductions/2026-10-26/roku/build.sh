#!/bin/sh
# Usage: build.sh <name> <sdk worktree>
set -e
here=$(cd "$(dirname "$0")" && pwd)
out="$here/build/$1"; rm -rf "$out"; mkdir -p "$out"
cp -R "$here/client/." "$out/"
cp "$2/source/Purchases.brs" "$out/source/Purchases.brs"
(cd "$out" && rm -f "$here/web/apps/$1.zip" && zip -qr "$here/web/apps/$1.zip" manifest source)
shasum -a 256 "$out/source/Purchases.brs" | sed "s#$out/##"
