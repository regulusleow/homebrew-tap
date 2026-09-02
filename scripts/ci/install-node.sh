#!/usr/bin/env bash
set -euo pipefail

if brew install node@22; then
  exit 0
fi

brew list --versions node@22 >/dev/null
NODE_PREFIX="$(brew --prefix node@22)"
"$NODE_PREFIX/bin/node" --version >/dev/null
