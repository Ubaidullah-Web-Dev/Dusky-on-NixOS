#!/usr/bin/env bash
set -euo pipefail

# NixOS Dusky System Updater
echo "========================================="
echo "       Dusky on NixOS System Updater     "
echo "========================================="

if command -v dusky-update >/dev/null 2>&1; then
    exec dusky-update ""
else
    cd /etc/nixos
    if [ -d .git ] && git remote get-url origin >/dev/null 2>&1; then
        echo "Pulling updates from git repository..."
        git pull --ff-only || echo "Proceeding with local configs..."
    fi
    sudo nixos-rebuild switch --flake /etc/nixos#dusky-nix
fi
