#!/usr/bin/env bash
# =============================================================================
# Suspend Diagnostic Tool - Step-by-Step Kernel Isolation
# =============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[*] Escalating to root with sudo..."
    exec sudo "$0" "$@"
fi

# Always reset pm_test on exit
trap 'echo none > /sys/power/pm_test 2>/dev/null || true' EXIT

STAGE="${1:-devices}"

case "${STAGE}" in
    freezer|devices|platform|none) ;;
    *)
        echo "Usage: sudo $0 [freezer|devices|platform|none]"
        exit 1
        ;;
esac

echo "=========================================================="
echo " Testing Suspend Subsystem: ${STAGE}"
echo "=========================================================="

echo "${STAGE}" > /sys/power/pm_test
echo "[+] Set /sys/power/pm_test to '${STAGE}'."

if [[ "${STAGE}" == "none" ]]; then
    echo "[*] Reset pm_test to normal. Exiting."
    exit 0
fi

echo "[*] Suspending now (auto-resume in 5 seconds)..."
sleep 1
echo mem > /sys/power/state

echo ""
echo "=========================================================="
echo " [SUCCESS] Subsystem '${STAGE}' resumed successfully!"
echo "=========================================================="
