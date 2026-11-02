#!/usr/bin/env bash
# Dusky on NixOS - Waybar Update Counter
set -euo pipefail

SHOW_NIX=0
SHOW_DUSKY=0
MODULE_ORDER=()
TIMEOUT_SEC=15
STATE_DIR="$HOME/.config/dusky/settings"
mkdir -p "$STATE_DIR"

# Parse Arguments
for arg in "$@"; do
    case "$arg" in
        --nix|--nixos|--pacman)
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
            printf "Usage: %s [--nix] [--dusky]\n" "${0##*/}"
            exit 0
            ;;
    esac
done

if (( ${#MODULE_ORDER[@]} == 0 )); then
    MODULE_ORDER=("nix" "dusky")
    SHOW_NIX=1
    SHOW_DUSKY=1
fi

# Network connectivity check
if ! timeout 3 ping -q -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    off_json='{"text":"󰸞 ?","tooltip":"Offline. Last state unknown.","class":"updated"}'
    printf '%s\n' "$off_json" > "$STATE_DIR/waybar_update_counter_h"
    printf '%s\n' "$off_json" > "$STATE_DIR/waybar_update_counter_v"
    exit 0
fi

TMP_DIR=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/dusky_updates.XXXXXX")
trap 'set +e; [[ -n "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"; rm -f "$STATE_DIR"/waybar_update_counter_*.tmp 2>/dev/null' EXIT

# NixOS package updates are managed declaratively via flake / system generations
if (( SHOW_NIX )); then
    echo "0" > "$TMP_DIR/nix"
fi

if (( SHOW_DUSKY )); then
    DSK_FILE="$STATE_DIR/dusky_update_behind_commit"
    if [[ -r "$DSK_FILE" && -f "$DSK_FILE" && ! -p "$DSK_FILE" ]]; then
        val=""
        read -t 1 -r val < "$DSK_FILE" 2>/dev/null || true
        if [[ -n "${val:-}" && "$val" =~ ^[0-9]+$ ]]; then
            echo "$val" > "$TMP_DIR/dsk"
        else
            echo "0" > "$TMP_DIR/dsk"
        fi
    else
        echo "0" > "$TMP_DIR/dsk"
    fi
fi

declare -i NIX_COUNT=0
declare -i DSK_COUNT=0
[[ -s "$TMP_DIR/nix" ]] && NIX_COUNT=$(<"$TMP_DIR/nix") || NIX_COUNT=0
[[ -s "$TMP_DIR/dsk" ]] && DSK_COUNT=$(<"$TMP_DIR/dsk") || DSK_COUNT=0

render_axis() {
    local axis="$1"
    local suffix="$2"
    local file="$STATE_DIR/waybar_update_counter_${suffix}"

    jq -c -n \
        --arg mode "$axis" \
        --arg order "${MODULE_ORDER[*]:-}" \
        --argjson nix_c "$NIX_COUNT" \
        --argjson dsk_c "$DSK_COUNT" '

        def clamp: if . > 999 then 999 else . end;
        def pad3:
            tostring | length as $l |
            if $l >= 3 then .
            elif $l == 2 then "\u2005" + . + "\u2005"
            elif $l == 1 then " " + . + " "
            else "   " end;

        "" as $nix_icon | "󰚰" as $dsk_icon | "󰸞" as $check_icon |
        ($nix_c + $dsk_c) as $total |

        if $total == 0 then
            {
                "text": (if $mode == "vertical" then ("0" | pad3) + "\n" + ($check_icon | pad3) else "\($check_icon) 0" end),
                "tooltip": "System is completely up to date.",
                "class": "updated"
            }
        else
            ($order | split(" ") | map(
                if . == "nix" and $nix_c > 0 then
                    { c: ($nix_c | clamp), i: $nix_icon, name: "NixOS", desc: "NixOS Flake Packages" }
                elif . == "dusky" and $dsk_c > 0 then
                    { c: ($dsk_c | clamp), i: $dsk_icon, name: "Dusky", desc: "Dusky Git Commits" }
                else empty end
            )) as $items |

            (if $mode == "vertical" then
                ($items | map("\( .c | pad3 )\n\( .i | pad3 )") | join("\n\n"))
            else
                ($items | map("\(.i) \(.c)") | join("  "))
            end) as $text |

            ($items | map("• \(.name): \(.c)\n  └ \(.desc)") | join("\n\n")) as $tooltip_details |

            {
                "text": $text,
                "tooltip": "Pending Updates (Total: \($total))\n────────────────────────────\n\($tooltip_details)",
                "class": "pending"
            }
        end
    ' > "${file}.tmp"

    mv "${file}.tmp" "$file"
}

render_axis "horizontal" "h"
render_axis "vertical" "v"
