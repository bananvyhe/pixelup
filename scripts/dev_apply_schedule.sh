#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

cd "$ROOT_DIR"
bundle exec whenever --update-crontab pixelup_development --set "environment=development&path=$ROOT_DIR"
echo "Whenever crontab updated for pixelup_development"
