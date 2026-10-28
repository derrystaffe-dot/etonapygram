#!/usr/bin/env bash
# Regenerates patches/etonapygram.patch from a Telegram-iOS checkout that has the mod applied
# and further edits made in place. New files belong in mod/, not in the patch.
#   scripts/make-patch.sh <path-to-Telegram-iOS>
set -euo pipefail

MOD_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TG_ROOT="$(cd "${1:?usage: make-patch.sh <path-to-Telegram-iOS>}" && pwd)"

cd "$TG_ROOT"
git diff --no-color --no-ext-diff HEAD -- . > "$MOD_ROOT/patches/etonapygram.patch"
echo "etonapygram: wrote $(grep -c '^diff --git' "$MOD_ROOT/patches/etonapygram.patch") file diffs"
