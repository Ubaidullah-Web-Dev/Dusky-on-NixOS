#!/usr/bin/env bash
# ==============================================================================
# Ensure Python 3.15 runtime is installed on NixOS
# ==============================================================================
set -euo pipefail

if ! command -v python3.15 &>/dev/null; then
    echo "[INFO] Installing Python 3.15 via nix profile..."
    nix profile add nixpkgs#python315 || true
fi
