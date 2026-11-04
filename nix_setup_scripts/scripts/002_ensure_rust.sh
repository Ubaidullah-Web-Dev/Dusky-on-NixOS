#!/usr/bin/env bash
# ==============================================================================
# Ensure Cargo and Rustc runtime is installed on NixOS
# ==============================================================================
set -euo pipefail

if ! command -v cargo &>/dev/null || ! command -v rustc &>/dev/null; then
    echo "[INFO] Installing Cargo & Rustc via nix profile..."
    nix profile add nixpkgs#cargo nixpkgs#rustc || true
fi
