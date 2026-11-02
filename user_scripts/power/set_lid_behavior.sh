#!/usr/bin/env bash
# =============================================================================
# Dusky Power - Quick Lid Switch Configuration
# =============================================================================
# Usage:
#   sudo ~/user_scripts/power/set_lid_behavior.sh lock     # Recommended for HP G7
#   sudo ~/user_scripts/power/set_lid_behavior.sh suspend  # Deep sleep (s2idle)
#   sudo ~/user_scripts/power/set_lid_behavior.sh ignore   # Clamshell mode
# =============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[*] Escalating to root with sudo..."
    exec sudo "$0" "$@"
fi

ACTION="${1:-lock}"

case "${ACTION}" in
    lock|suspend|ignore) ;;
    *)
        echo "[-] Invalid action: ${ACTION}"
        echo "Usage: sudo $0 [lock|suspend|ignore]"
        exit 1
        ;;
esac

mkdir -p /etc/systemd/logind.conf.d

cat > /etc/systemd/logind.conf.d/99-power.conf << EOF
# =============================================================================
# Managed strictly by Dusky TUI - Systemd Power Manager
# Target: systemd-logind drop-in configuration
# =============================================================================
[Login]
HandleLidSwitch=${ACTION}
HandleLidSwitchExternalPower=${ACTION}
HandleLidSwitchDocked=ignore
HoldoffTimeoutSec=10s
EOF

systemctl reload systemd-logind.service
echo "[+] Successfully set lid close action to '${ACTION}'!"
echo "[+] Reloaded systemd-logind (changes are active IMMEDIATELY, no reboot needed)."
