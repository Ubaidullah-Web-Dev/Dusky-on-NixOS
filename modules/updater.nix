{ pkgs, ... }:

let
  dusky-update = pkgs.writeShellScriptBin "dusky-update" ''
    set -euo pipefail

    echo "=== Dusky on NixOS Updater ==="
    FLAKE_DIR="/etc/nixos"
    cd "$FLAKE_DIR"

    if [ -d .git ]; then
      if sudo git remote get-url origin >/dev/null 2>&1; then
        echo "Pulling updates from git repository..."
        sudo git pull --ff-only || {
          echo "Warning: git pull failed or local changes exist. Proceeding with local configs..."
        }
      else
        echo "Local git repo detected without remote origin."
      fi
    fi

    # Update flake inputs if --flake-update or -u was passed
    for arg in "$@"; do
      if [ "$arg" = "--flake-update" ] || [ "$arg" = "-u" ]; then
        echo "Updating flake inputs..."
        sudo nix flake update
      fi
    done

    echo "Building and switching to new NixOS configuration..."
    sudo nixos-rebuild switch --flake "$FLAKE_DIR#dusky-nix"

    echo "=== Dusky on NixOS update complete! ==="
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "Dusky on Nix" "System update completed successfully!" -i system-software-update || true
    fi
  '';

  dusky-rollback = pkgs.writeShellScriptBin "dusky-rollback" ''
    set -euo pipefail

    echo "=== Dusky on NixOS Rollback ==="
    echo "Rolling back to previous generation..."
    sudo nixos-rebuild switch --rollback

    echo "=== Rollback complete! ==="
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "Dusky on Nix" "Rolled back to previous generation." -i system-software-update || true
    fi
  '';
in
{
  environment.systemPackages = [ dusky-update dusky-rollback ];
}
