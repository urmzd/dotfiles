#!/usr/bin/env bash
# Separate from the AI-tools sentinel so existing machines install OpenCode too.
set -euo pipefail
if ! command -v opencode >/dev/null 2>&1 && [[ ! -x "$HOME/.opencode/bin/opencode" ]]; then
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
fi
