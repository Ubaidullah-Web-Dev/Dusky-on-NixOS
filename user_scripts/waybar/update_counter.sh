#!/usr/bin/env bash
# Cached NixOS and Dusky counts for Waybar and the quick panel.

# FOR Horizontal WAYBARS
# "custom/updates": {
#     "exec": "tail -F ~/.config/dusky/settings/waybar_update_counter_h 2>/dev/null",
#     "return-type": "json",
#     "format": "{}",
#     "tooltip": true
# }

# FOR Vertical WAYBARS
# "custom/updates": {
#     "exec": "tail -F ~/.config/dusky/settings/waybar_update_counter_v 2>/dev/null",
#     "return-type": "json",
#     "format": "{}",
#     "tooltip": true
# }

set -euo pipefail

# ---------------------------------------------------------
# Configuration & Defaults
# ---------------------------------------------------------
SHOW_NIX=0
SHOW_DUSKY=0
MODULE_ORDER=()
TIMEOUT_SEC=15
STATE_DIR="$HOME/.config/dusky/settings"

# Parse Arguments
for arg in "$@"; do
    case "$arg" in
        --nix|--nixos|--pacman|--aur)
            if [[ $SHOW_NIX -eq 0 ]]; then
                MODULE_ORDER+=("nix")
                SHOW_NIX=1
            fi
            ;;
        --dusky)
            if [[ $SHOW_DUSKY -eq 0 ]]; then
                MODULE_ORDER+=("dusky")
                SHOW_DUSKY=1
            fi
            ;;
        -h|--help)
            printf "Usage: %s [--nix] [--dusky] (default: all)\n" "${0##*/}"
            exit 0
            ;;
    esac
done

# Check all categories by default if no flags passed
if (( ${#MODULE_ORDER[@]} == 0 )); then
    SHOW_NIX=1
    SHOW_DUSKY=1
    MODULE_ORDER=(nix dusky)
fi

mkdir -p -- "$STATE_DIR"
command -v jq >/dev/null 2>&1 || exit 0
exec {lock_fd}> "$STATE_DIR/.waybar_update_counter.lock"
flock --nonblocking "$lock_fd" || exit 0
TMP_DIR=$(mktemp -d "$STATE_DIR/.dusky_updates.XXXXXX")
cleanup() {
    local -a pids=()
    mapfile -t pids < <(jobs -pr)
    if (( ${#pids[@]} )); then
        kill -- "${pids[@]}" 2>/dev/null || true
        wait "${pids[@]}" 2>/dev/null || true
    fi
    rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

if (( SHOW_NIX )); then
    # Declarative NixOS system updates
    printf '0\n' > "$TMP_DIR/nix"
fi
wait

# Read the commit snapshot after package queries so resets/checks completed
# during network I/O are reflected in the cache we are about to publish.
if (( SHOW_DUSKY )); then
    val=''
    if [[ -f "$STATE_DIR/dusky_update_behind_commit" ]]; then
        IFS= read -r val < "$STATE_DIR/dusky_update_behind_commit" || true
    fi
    printf '%s\n' "$val" > "$TMP_DIR/dsk"
fi

# ---------------------------------------------------------
# Data Sanitization
# ---------------------------------------------------------
sanitize_count() {
    local file="$1"
    local -n ref_var="$2"
    ref_var="null"

    if [[ -s "$file" ]]; then
        local raw=""
        read -r raw < "$file" || true
        if [[ "$raw" =~ ^[0-9]{1,18}$ ]]; then
            # shellcheck disable=SC2034 # Writes through the caller's nameref.
            ref_var=$(( 10#$raw ))
        fi
    fi
}

declare NIX_COUNT DSK_COUNT
sanitize_count "$TMP_DIR/nix" NIX_COUNT
sanitize_count "$TMP_DIR/dsk" DSK_COUNT

# ---------------------------------------------------------
# Dual-Axis JSON Rendering
# ---------------------------------------------------------
render_axis() {
    local axis="$1"
    local suffix="$2"
    local file="$STATE_DIR/waybar_update_counter_${suffix}"

    jq -c -n \
        --argjson nix_c "$NIX_COUNT" \
        --argjson dsk_c "$DSK_COUNT" \
        --arg order "${MODULE_ORDER[*]}" \
        --arg mode "$axis" '
        def pad3:
            tostring |
            length as $l |
            if $l >= 3 then .
            elif $l == 2 then "\u2005" + . + "\u2005"
            elif $l == 1 then " " + . + " "
            else "   " end;

        "" as $nix_icon | "󰚰" as $dsk_icon | "󰸞" as $check_icon |

        ($order | split(" ")) as $selected |
        {nix: $nix_c, dusky: $dsk_c} |
        with_entries(.key as $key | select($selected | index($key))) as $counts |
        ([$counts[] | . // 0] | add) as $total |
        ([$counts | to_entries[] | select(.value == null) | .key] | join(", ")) as $unknown |

        if $total == 0 and $unknown != "" then
            {
                "text": "󰸞 ?",
                "tooltip": "Update counts unavailable: \($unknown).",
                "class": "unknown"
            }
        elif $total == 0 then
            {
                "text": (if $mode == "vertical" then ("0" | pad3) + "\n" + ($check_icon | pad3) else "\($check_icon) 0" end),
                "tooltip": "No pending updates in the checked categories.",
                "class": "updated"
            }
        else
            if $mode == "vertical" then
                [
                    if $selected | index("nix") then ($nix_c // "?" | tostring | pad3) + "\n" + ($nix_icon | pad3) else empty end,
                    if $selected | index("dusky") then ($dsk_c // "?" | tostring | pad3) + "\n" + ($dsk_icon | pad3) else empty end
                ] | join("\n")
            else
                [
                    if $selected | index("nix") then "\($nix_icon) \($nix_c // "?")" else empty end,
                    if $selected | index("dusky") then "\($dsk_icon) \($dsk_c // "?")" else empty end
                ] | join("  ")
            end as $text |
            [
                if $selected | index("nix") then "• NixOS:    \($nix_c // "Unavailable")" else empty end,
                if $selected | index("dusky") then "• Dusky:    \($dsk_c // "Unavailable")" else empty end
            ] | join("\n") as $tooltip_details |

            {
                "text": $text,
                "tooltip": ("Pending System Updates (Total: \($total))\n────────────────────────────\n\($tooltip_details)" + if $unknown != "" then "\n\nCounts unavailable: \($unknown)." else "" end),
                "class": "pending"
            }
        end | . + {counts: $counts}
    ' > "$TMP_DIR/axis_${suffix}"

    mv --force --no-target-directory -- "$TMP_DIR/axis_${suffix}" "$file"
}

# Publish each axis with an atomic rename
render_axis "horizontal" "h"
render_axis "vertical" "v"
