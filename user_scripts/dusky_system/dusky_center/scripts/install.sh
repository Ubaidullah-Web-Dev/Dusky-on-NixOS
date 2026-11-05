#!/usr/bin/env bash
# Use the same package/native selection as the setup profiles; never launch the UI.
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly PROJECT_DIR
for candidate in \
    "$PROJECT_DIR/../../nix_setup_scripts/scripts/153_dusky_center_setup.py" \
    "$PROJECT_DIR/../../user_scripts/nix_setup_scripts/scripts/153_dusky_center_setup.py" \
    "$HOME/nix_setup_scripts/scripts/153_dusky_center_setup.py" \
    "$HOME/user_scripts/nix_setup_scripts/scripts/153_dusky_center_setup.py"; do
    if [[ -f "$candidate" ]]; then
        exec python3 "$candidate" "$@"
    fi
done
echo "Error: 153_dusky_center_setup.py not found" >&2
exit 1
