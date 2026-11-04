#!/usr/bin/env bash
# ==============================================================================
# Ensure Cargo, Rustc, pkg-config, and xkbcommon dev libraries on NixOS
# ==============================================================================
set -euo pipefail

if ! command -v cargo &>/dev/null || ! command -v rustc &>/dev/null || ! command -v pkg-config &>/dev/null; then
    echo "[INFO] Installing Cargo, Rustc, pkg-config & libxkbcommon via nix profile..."
    nix profile add nixpkgs#cargo nixpkgs#rustc nixpkgs#pkg-config nixpkgs#libxkbcommon.dev || true
fi
