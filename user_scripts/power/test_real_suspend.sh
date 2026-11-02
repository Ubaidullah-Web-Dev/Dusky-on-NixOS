#!/usr/bin/env bash
# =============================================================================
# Dusky Power - Hardware RTC Suspend Verification
# =============================================================================
# Tests true s2idle sleep using the motherboard RTC hardware alarm.
# Auto-wakes after 5 seconds regardless of lid switch or button input.
# =============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[*] Escalating to root with sudo..."
    exec sudo "$0" "$@"
fi

echo "=========================================================="
echo " Testing True s2idle Suspend (5-Second RTC Auto-Wake)"
echo "=========================================================="

# Ensure pm_test is none
echo none > /sys/power/pm_test
echo "[+] Verified /sys/power/pm_test is 'none'."
echo "[+] Active sleep mode: $(cat /sys/power/mem_sleep)"

echo ""
echo "[*] Going to sleep NOW. Screen will turn black."
echo "[*] The hardware alarm will automatically wake the laptop in 5 seconds."
echo "[*] DO NOT touch any keys or the power button during the 5 seconds."
echo ""
sleep 2

# Log before sleep
logger -t test_suspend "TEST_SUSPEND: Initiating 5-second rtcwake"

# Run rtcwake
rtcwake -m freeze -s 5

echo ""
echo "=========================================================="
echo " [SUCCESS] System resumed from true s2idle sleep!"
echo "=========================================================="
logger -t test_suspend "TEST_SUSPEND: Resumed successfully"
