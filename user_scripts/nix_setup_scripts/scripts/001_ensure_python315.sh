#!/usr/bin/env bash
# ==============================================================================
# Ensure Python 3.15 runtime and TUI packages are configured on NixOS
# ==============================================================================
set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")
SITE_PACKAGES_DIR="$USER_HOME/.local/lib/python3.15/site-packages"

mkdir -p "$SITE_PACKAGES_DIR"
cat << 'EOF' > "$SITE_PACKAGES_DIR/nixos_sys_packages.pth"
/run/current-system/sw/lib/python3.15/site-packages
/run/current-system/sw/lib/python3.14/site-packages
EOF
chown -R "$TARGET_USER:" "$USER_HOME/.local/lib" 2>/dev/null || true

if ! command -v python3.15 &>/dev/null; then
    echo "[INFO] Installing Python 3.15 via nix profile..."
    nix profile add nixpkgs#python315 || true
fi
