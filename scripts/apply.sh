#!/usr/bin/env bash
# Applies the etonapygram mod to a Telegram-iOS checkout.
#   scripts/apply.sh <path-to-Telegram-iOS>
set -euo pipefail

MOD_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TG_ROOT="$(cd "${1:?usage: apply.sh <path-to-Telegram-iOS>}" && pwd)"

echo "etonapygram: copying mod sources into $TG_ROOT"
cp -R "$MOD_ROOT/mod/." "$TG_ROOT/"

cd "$TG_ROOT"
for patch in "$MOD_ROOT"/patches/*.patch; do
    [ -e "$patch" ] || continue
    echo "etonapygram: applying $(basename "$patch")"
    git apply --whitespace=nowarn "$patch"
done

echo "etonapygram: done"
