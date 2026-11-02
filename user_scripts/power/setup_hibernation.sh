#!/usr/bin/env bash
# =============================================================================
# Dusky Power - Setup Hibernation (S4) for HP EliteBook 845 G7
# =============================================================================
# Provides 0.00W power draw (zero battery drain overnight), saves all open apps
# to SSD, and avoids the broken HP s2idle firmware freeze completely.
# =============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[*] Escalating to root with sudo..."
    exec sudo "$0" "$@"
fi

SWAP_FILE="/swap/swapfile"
SWAP_SIZE="16g"
ENTRIES_DIR="/boot/loader/entries"
ENTRY_FILE="${ENTRIES_DIR}/arch-linux.conf"
ROOT_UUID="9dca7c1a-2aed-4998-afb5-5da5ff11ac50"
LOGIND_DROPIN_FILE="/etc/systemd/logind.conf.d/99-power.conf"

echo "=========================================================="
echo " Setting up Hibernation (Suspend-to-Disk) - Zero Battery Drain"
echo "=========================================================="

# 1. Expand /swap/swapfile to 16GB using native btrfs tool
echo "[1/4] Preparing 16GB Btrfs swapfile at ${SWAP_FILE}..."
if swapon --show | grep -q "${SWAP_FILE}"; then
    swapoff "${SWAP_FILE}"
fi

rm -f "${SWAP_FILE}"
mkdir -p /swap
btrfs filesystem mkswapfile --size "${SWAP_SIZE}" "${SWAP_FILE}"
swapon "${SWAP_FILE}"
echo "[+] 16GB swapfile active."

# 2. Compute Btrfs resume offset
echo "[2/4] Calculating Btrfs resume offset..."
RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r "${SWAP_FILE}")
echo "[+] Found resume_offset: ${RESUME_OFFSET}"

# 3. Configure bootloader kernel parameters
echo "[3/4] Adding resume parameters to ${ENTRY_FILE}..."
cp -v "${ENTRY_FILE}" "${ENTRY_FILE}.backup-pre-hibernate"

OPTIONS_LINE=$(grep "^options" "${ENTRY_FILE}")
NEW_OPTIONS="${OPTIONS_LINE}"

# Remove any old resume parameters if present
NEW_OPTIONS=$(echo "${NEW_OPTIONS}" | sed -E 's/resume=[^ ]+//g; s/resume_offset=[^ ]+//g' | tr -s ' ')

# Append clean resume parameters
NEW_OPTIONS="${NEW_OPTIONS} resume=UUID=${ROOT_UUID} resume_offset=${RESUME_OFFSET}"

sed -i "s|^options.*|${NEW_OPTIONS}|" "${ENTRY_FILE}"
echo "[+] Updated kernel cmdline: ${NEW_OPTIONS}"

# 4. Set lid close action to hibernate
echo "[4/4] Setting lid close action to 'hibernate' in ${LOGIND_DROPIN_FILE}..."
mkdir -p /etc/systemd/logind.conf.d
cat > "${LOGIND_DROPIN_FILE}" << 'EOF'
# =============================================================================
# Managed strictly by Dusky TUI - Systemd Power Manager
# Target: systemd-logind drop-in configuration
# =============================================================================
[Login]
HandleLidSwitch=hibernate
HandleLidSwitchExternalPower=hibernate
HandleLidSwitchDocked=ignore
HoldoffTimeoutSec=10s
EOF

systemctl reload systemd-logind.service
echo "[+] systemd-logind reloaded with lid action: hibernate."

echo ""
echo "=========================================================="
echo " [SUCCESS] Hibernation successfully configured!"
echo "=========================================================="
echo " Next steps:"
echo " 1. Reboot your laptop so the kernel recognizes the new resume offset."
echo " 2. Once rebooted, test closing your lid or running:"
echo "      systemctl hibernate"
echo " 3. The laptop will save state and power COMPLETELY off (0W draw)."
echo " 4. Press the power button to wake — all your open windows will restore!"
echo "=========================================================="
