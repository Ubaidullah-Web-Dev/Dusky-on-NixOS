#!/usr/bin/env bash
# =============================================================================
# Dusky Power / Arch Linux - Renoir Display & Power Fix (HP EliteBook 845 G7)
# =============================================================================
# Fixes:
#   1. amdgpu.dcdebugmask=0x10  -> Disables Panel Self-Refresh (PSR) which causes
#                                  the screen to stay 100% black on wake from sleep.
#   2. amdgpu.sg_display=0      -> Disables Scatter/Gather scanout buffer bug on
#                                  Renoir APUs which causes blank display on wake.
#   3. iommu=pt                 -> Bypasses IOMMU page faults during display wake.
#   4. ahci.mobile_lpm_policy=1 -> Keeps SATA SSD link alive across sleep cycles.
#
# Removes (Toxic):
#   - pcie_aspm=off, idle=nomwait, acpi.ec_no_wakeup=1, amdgpu.aspm=0, acpi_osi=...
# =============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[*] Escalating to root with sudo..."
    exec sudo "$0" "$@"
fi

ENTRIES_DIR="/boot/loader/entries"
ENTRY_FILE="${ENTRIES_DIR}/arch-linux.conf"
LOGIND_DROPIN_DIR="/etc/systemd/logind.conf.d"
LOGIND_DROPIN_FILE="${LOGIND_DROPIN_DIR}/99-power.conf"

echo "=========================================================="
echo " Applying Renoir Display & Suspend Fix (HP EliteBook 845 G7)"
echo "=========================================================="

if [[ ! -f "${ENTRY_FILE}" ]]; then
    FOUND=$(find "${ENTRIES_DIR}" -maxdepth 1 -name "*.conf" ! -name "*fallback*" | head -n 1)
    if [[ -n "${FOUND}" ]]; then
        ENTRY_FILE="${FOUND}"
    else
        echo "[-] Error: Could not locate systemd-boot entry in ${ENTRIES_DIR}"
        exit 1
    fi
fi

OPTIONS_LINE=$(grep "^options" "${ENTRY_FILE}" || true)
if [[ -z "${OPTIONS_LINE}" ]]; then
    echo "[-] Error: No 'options' line found in ${ENTRY_FILE}"
    exit 1
fi

NEW_OPTIONS="${OPTIONS_LINE}"

# 1. Purge toxic parameters
TOXIC_PARAMS=(
    "pcie_aspm=off"
    "amdgpu.aspm=0"
    "acpi.ec_no_wakeup=1"
    "idle=nomwait"
    "tsc=reliable"
    "acpi_osi=\"Windows 2020\""
    "acpi_osi=Windows 2020"
)

for param in "${TOXIC_PARAMS[@]}"; do
    NEW_OPTIONS=$(echo "${NEW_OPTIONS}" | sed -E "s|[[:space:]]*${param}[[:space:]]*| |g")
done

# 2. Ensure targeted Renoir display fixes are present
RENOIR_FIXES=(
    "amdgpu.dcdebugmask=0x10"
    "amdgpu.sg_display=0"
    "iommu=pt"
    "ahci.mobile_lpm_policy=1"
)

for fix in "${RENOIR_FIXES[@]}"; do
    if ! grep -q "${fix}" <<< "${NEW_OPTIONS}"; then
        NEW_OPTIONS="${NEW_OPTIONS} ${fix}"
    fi
done

# Normalize whitespace
NEW_OPTIONS=$(echo "${NEW_OPTIONS}" | sed -E 's/[[:space:]]+/ /g' | sed -E 's/[[:space:]]+$//')

sed -i "s|^options.*|${NEW_OPTIONS}|" "${ENTRY_FILE}"
echo "[+] Updated kernel parameters in ${ENTRY_FILE}:"
echo "    ${NEW_OPTIONS}"

# 3. Reset /sys/power/pm_test to 'none'
if [[ -f /sys/power/pm_test ]]; then
    echo none > /sys/power/pm_test
    echo "[+] Reset /sys/power/pm_test to 'none'."
fi

# 4. Configure systemd-logind drop-in
echo "[+] Configuring systemd-logind..."
mkdir -p "${LOGIND_DROPIN_DIR}"
cat > "${LOGIND_DROPIN_FILE}" << 'EOF'
# =============================================================================
# Managed strictly by Dusky TUI - Systemd Power Manager
# Target: systemd-logind drop-in configuration
# =============================================================================
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
HoldoffTimeoutSec=10s
EOF

systemctl reload systemd-logind.service 2>/dev/null || true
echo "[+] Reloaded systemd-logind."

echo ""
echo "=========================================================="
echo " [SUCCESS] Settings applied!"
echo "=========================================================="
echo " Active Options: $(grep "^options" "${ENTRY_FILE}")"
echo "=========================================================="
