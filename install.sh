#!/usr/bin/env bash
# ==============================================================================
#  DUSKY ON NIXOS - MASTER INSTALLER & BOOTSTRAPPER
# ==============================================================================
#  Repo: https://github.com/Ubaidullah-Web-Dev/Dusky-on-NixOS
# ==============================================================================

set -euo pipefail

C_RESET='\033[0m'
C_BOLD='\033[1m'
C_BLUE='\033[1;34m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_CYAN='\033[1;36m'

log_info() { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_ok() { printf "${C_GREEN}[OK]${C_RESET} %s\n" "$1"; }
log_warn() { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_err() { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$1" >&2; }

BANNER="
${C_CYAN}${C_BOLD}
  ██████╗ ██╗   ██╗███████╗██╗  ██╗██╗   ██╗     ███╗   ██╗██╗██╗  ██╗
  ██╔══██╗██║   ██║██╔════╝██║ ██╔╝╚██╗ ██╔╝     ████╗  ██║██║╚██╗██╔╝
  ██║  ██║██║   ██║███████╗█████═╝  ╚████╔╝█████╗██╔██╗ ██║██║ ╚███╔╝ 
  ██║  ██║██║   ██║╚════██║██╔═██╗   ╚██╔╝ ╚════╝██║╚██╗██║██║ ██╔██╗ 
  ██████╔╝╚██████╔╝███████║██║  ██╗   ██║        ██║ ╚████║██║██╔╝ ██╗
  ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝        ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
${C_RESET}
  ${C_BOLD}Pure Dusky Wayland Desktop Environment on NixOS${C_RESET}
  ${C_BLUE}Reproducible · Blazing Fast · Declarative · Zero Bloat${C_RESET}
"

printf "%b\n" "$BANNER"

# Pre-flight checks
if [[ ! -f /etc/NIXOS ]]; then
    log_err "This installer is designed specifically for NixOS."
    log_err "/etc/NIXOS not found. Aborting."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
AUTO_MODE=0

for arg in "$@"; do
    case "$arg" in
        --auto|--yes|-y|-f|--force)
            AUTO_MODE=1
            ;;
    esac
done

deploy_nixos_flake() {
    log_info "Deploying NixOS system configuration to /etc/nixos..."
    sudo mkdir -p /etc/nixos/modules

    # Preserve host hardware configuration if present
    if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
        log_info "Preserving existing /etc/nixos/hardware-configuration.nix"
    else
        log_info "Generating host hardware configuration..."
        sudo nixos-generate-config --dir /tmp/nixos-gen
        sudo cp /tmp/nixos-gen/hardware-configuration.nix /etc/nixos/
        rm -rf /tmp/nixos-gen
    fi

    # Copy flake files
    sudo cp -f "$SCRIPT_DIR/flake.nix" /etc/nixos/
    [[ -f "$SCRIPT_DIR/flake.lock" ]] && sudo cp -f "$SCRIPT_DIR/flake.lock" /etc/nixos/
    sudo cp -f "$SCRIPT_DIR/configuration.nix" /etc/nixos/
    sudo cp -rf "$SCRIPT_DIR/modules/"* /etc/nixos/modules/

    log_info "Building and activating NixOS configuration (using pre-built binary caches)..."
    sudo nixos-rebuild switch --flake /etc/nixos#dusky-nix
    log_ok "NixOS system switch complete!"
}

deploy_dotfiles_and_scripts() {
    log_info "Deploying Dusky configurations & user scripts to $TARGET_HOME..."

    # Ensure target directories exist
    mkdir -p "$TARGET_HOME/.config"
    mkdir -p "$TARGET_HOME/user_scripts"
    mkdir -p "$TARGET_HOME/Pictures/wallpapers"
    mkdir -p "$TARGET_HOME/Pictures/readme_assets"

    # Copy dotfiles
    if [[ -d "$SCRIPT_DIR/.config" ]]; then
        log_info "Syncing .config..."
        cp -rn "$SCRIPT_DIR/.config/"* "$TARGET_HOME/.config/" 2>/dev/null || true
    fi

    # Copy user_scripts
    if [[ -d "$SCRIPT_DIR/user_scripts" ]]; then
        log_info "Syncing user_scripts..."
        cp -rn "$SCRIPT_DIR/user_scripts/"* "$TARGET_HOME/user_scripts/" 2>/dev/null || true
    fi

    # Copy nix_setup_scripts
    if [[ -d "$SCRIPT_DIR/nix_setup_scripts" ]]; then
        log_info "Syncing nix_setup_scripts..."
        mkdir -p "$TARGET_HOME/user_scripts/nix_setup_scripts"
        cp -rn "$SCRIPT_DIR/nix_setup_scripts/"* "$TARGET_HOME/user_scripts/nix_setup_scripts/" 2>/dev/null || true
    fi

    # Copy wallpaper
    if [[ -d "$SCRIPT_DIR/Pictures" ]]; then
        cp -rn "$SCRIPT_DIR/Pictures/"* "$TARGET_HOME/Pictures/" 2>/dev/null || true
    fi

    # Copy .zshrc
    if [[ -f "$SCRIPT_DIR/.zshrc" ]]; then
        cp -f "$SCRIPT_DIR/.zshrc" "$TARGET_HOME/.zshrc"
    fi

    # Ensure correct permissions
    chown -R "$TARGET_USER:" "$TARGET_HOME/.config" "$TARGET_HOME/user_scripts" "$TARGET_HOME/Pictures" "$TARGET_HOME/.zshrc" 2>/dev/null || true
    log_ok "Configurations deployed!"
}

run_orchestra() {
    log_info "Running Dusky ORCHESTRA (78 battle-tested NixOS setup steps)..."
    local orch="$TARGET_HOME/user_scripts/nix_setup_scripts/ORCHESTRA.sh"
    if [[ -f "$orch" ]]; then
        chmod +x "$orch"
        if [[ $AUTO_MODE -eq 1 ]]; then
            bash "$orch"
        else
            bash "$orch"
        fi
        log_ok "ORCHESTRA completed successfully!"
    else
        log_warn "ORCHESTRA.sh not found at $orch. Skipping."
    fi
}

main() {
    if [[ $AUTO_MODE -eq 0 ]]; then
        echo -e "${C_BOLD}Select Installation Mode:${C_RESET}"
        echo "1) Full System Installation (NixOS Flake + Dotfiles + ORCHESTRA) [Recommended]"
        echo "2) Deploy Dotfiles & Run ORCHESTRA only"
        echo "3) Deploy NixOS System Flake only"
        echo "4) Exit"
        read -r -p "Enter choice [1-4] (default: 1): " choice
        choice="${choice:-1}"
    else
        choice=1
    fi

    case "$choice" in
        1)
            deploy_nixos_flake
            deploy_dotfiles_and_scripts
            run_orchestra
            ;;
        2)
            deploy_dotfiles_and_scripts
            run_orchestra
            ;;
        3)
            deploy_nixos_flake
            ;;
        *)
            log_info "Exiting without making changes."
            exit 0
            ;;
    esac

    echo ""
    log_ok "Dusky on NixOS installation finished!"
    log_info "Please reboot your system for all environment changes to take full effect:"
    echo "  sudo reboot"
}

main "$@"
