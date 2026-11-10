#!/usr/bin/env bash
#d: Set up Waydroid for Android apps

set -Eeuo pipefail
shopt -s inherit_errexit nullglob

readonly C_RESET=$'\033[0m' C_GREEN=$'\033[1;32m' C_BLUE=$'\033[1;34m'
readonly C_RED=$'\033[1;31m' C_YELLOW=$'\033[1;33m'
readonly DEST_DIR=/etc/waydroid-extra/images
readonly WORK_DIR=/var/lib/waydroid
readonly SERVICE=waydroid-container.service
STAGE_DIR=''
TEMP_DIR=''

log_info()    { printf '%s[INFO]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
log_success() { printf '%s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
log_warn()    { printf '%s[WARN]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
log_error()   { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

cleanup() {
    local status=$?
    trap - EXIT
    [[ -z "$STAGE_DIR" ]] || rm -rf -- "$STAGE_DIR" || status=1
    [[ -z "$TEMP_DIR" ]] || rm -rf -- "$TEMP_DIR" || status=1
    exit "$status"
}

ask_yes() {
    local answer
    read -r -p "$1 [y/N] " answer || return 1
    [[ "$answer" == [Yy] ]]
}

expand_user_path() {
    # Quoted tildes are intentional: expand against the invoking user's home.
    # shellcheck disable=SC2088
    case "$1" in
        '~') printf '%s\n' "$REAL_HOME" ;;
        '~/'*) printf '%s/%s\n' "$REAL_HOME" "${1:2}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

ensure_packages() {
    if [[ -f /etc/NIXOS ]]; then
        return 0
    fi
    local package
    local -a missing=()
    for package in "$@"; do
        if command -v pacman >/dev/null 2>&1; then
            pacman -Qq "$package" >/dev/null 2>&1 || missing+=("$package")
        fi
    done
    if (( ${#missing[@]} )) && command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm --needed "${missing[@]}"
    fi
}

verify_environment() {
    if [[ ${EUID} -ne 0 ]]; then
        log_info 'Elevating to root privileges...'
        exec sudo WAYDROID_SETUP_RUNNING=1 "$0" "$@"
    fi

    REAL_USER=${SUDO_USER:-${DOAS_USER:-$(logname 2>/dev/null || echo '')}}
    [[ -n "$REAL_USER" && "$REAL_USER" != 'root' ]] || log_error 'Run via sudo from a normal user.'
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    readonly REAL_USER REAL_HOME
    log_info "Running as root. Host operations scoped to: $REAL_USER"

    ensure_packages git unzip lzip squashfs-tools

    if grep -qE 'binder' /proc/filesystems; then
        log_success 'BinderFS detected natively.'
    else
        log_warn 'Binder not found in /proc/filesystems. Probing module...'
        modprobe binder_linux 2>/dev/null || true
        grep -qE 'binder' /proc/filesystems || log_warn 'BinderFS not registered; reboot if newly installed.'
    fi
}

find_system_image() {
    local base=$1
    local file candidate
    for file in "$base"/lineage-*-system.img \
                "$base"/system.img \
                "$base"/lineage-*.zip; do
        [[ -f "$file" ]] || continue
        candidate=$file
        break
    done
    [[ -n "${candidate:-}" ]] || return 1
    printf '%s\n' "$candidate"
}

find_vendor_image() {
    local base=$1
    local file candidate
    for file in "$base"/lineage-*-vendor.img \
                "$base"/vendor.img; do
        [[ -f "$file" ]] || continue
        candidate=$file
        break
    done
    [[ -n "${candidate:-}" ]] || return 1
    printf '%s\n' "$candidate"
}

unpack_image_source() {
    local src=$1 dest=$2 label=$3
    mkdir -p -- "$dest"
    case "$src" in
        *.zip)
            log_info "Unpacking $label image from archive: $src"
            unzip -p "$src" "$label.img" > "$dest/$label.img"
            ;;
        *.img)
            log_info "Staging $label image: $src"
            cp --reflink=auto -- "$src" "$dest/$label.img"
            ;;
        *)
            log_error "Unsupported format for $label image: $src"
            ;;
    esac
}

discover_images() {
    local primary_dir=$1 fallback_dir=$2
    local sys_source='' ven_source=''

    if [[ -d "$primary_dir" ]]; then
        sys_source=$(find_system_image "$primary_dir" || true)
        ven_source=$(find_vendor_image "$primary_dir" || true)
    fi
    if [[ -z "$sys_source" || -z "$ven_source" ]] && [[ -d "$fallback_dir" ]]; then
        [[ -n "$sys_source" ]] || sys_source=$(find_system_image "$fallback_dir" || true)
        [[ -n "$ven_source" ]] || ven_source=$(find_vendor_image "$fallback_dir" || true)
    fi

    if [[ -z "$sys_source" || -z "$ven_source" ]]; then
        return 1
    fi

    printf '%s\n%s\n' "$sys_source" "$ven_source"
}

prompt_for_images() {
    local -a locations=()
    local input sys_source ven_source pair

    log_warn "Waydroid image pair could not be located automatically."
    log_info "Expected files: lineage-*-system.img (or system.img / lineage-*.zip) and lineage-*-vendor.img (or vendor.img)."

    while true; do
        read -r -p "Enter path to image directory, archive or 'abort': " input
        [[ "$input" != 'abort' ]] || log_error "Aborted by user."
        input=$(expand_user_path "$input")
        if [[ -d "$input" ]]; then
            if pair=$(discover_images "$input" "$input"); then
                read -r sys_source ven_source <<< "$pair"
                printf '%s\n%s\n' "$sys_source" "$ven_source"
                return 0
            fi
        fi
        log_warn "Could not resolve valid system and vendor images from: $input"
    done
}

stage_images() {
    local sys_source=$1 ven_source=$2
    STAGE_DIR=$(mktemp -d /var/tmp/waydroid-stage.XXXXXX)
    chmod 0755 "$STAGE_DIR"
    unpack_image_source "$sys_source" "$STAGE_DIR" 'system'
    unpack_image_source "$ven_source" "$STAGE_DIR" 'vendor'
}

install_images() {
    mkdir -p -- "$DEST_DIR"
    chmod 0755 "$DEST_DIR"
    local updated=0
    local label target staged
    for label in system vendor; do
        target=$DEST_DIR/$label.img
        staged=$STAGE_DIR/$label.img
        if [[ ! -f "$target" ]] || ! cmp -s -- "$staged" "$target"; then
            log_info "Updating destination image: $target"
            cp --reflink=auto -- "$staged" "$target.tmp"
            mv -f -- "$target.tmp" "$target"
            chmod 0644 "$target"
            updated=1
        fi
    done
    return "$(( updated ? 0 : 1 ))"
}

configure_waydroid() {
    local needs_init=0 refresh=0
    local cfg=$WORK_DIR/waydroid.cfg
    local prop=$WORK_DIR/waydroid_base.prop

    if [[ ! -f "$cfg" ]] || ! grep -qF "images_path = $DEST_DIR" "$cfg" 2>/dev/null; then
        needs_init=1
    fi
    if [[ ! -f "$prop" ]] || ! grep -qF 'persist.waydroid.multi_windows=true' "$prop" 2>/dev/null; then
        if [[ -f "$prop" ]]; then
            printf '\npersist.waydroid.multi_windows=true\n' >> "$prop"
            refresh=1
        else
            needs_init=1
        fi
    fi
    printf '%d %d\n' "$needs_init" "$refresh"
}

configure_firewall() {
    if [[ $(sysctl -n net.ipv4.ip_forward) -eq 0 ]]; then
        printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.d/99-waydroid.conf
        sysctl -p /etc/sysctl.d/99-waydroid.conf >/dev/null
        log_success 'IPv4 forwarding activated.'
    fi

    if systemctl is-active --quiet firewalld; then
        firewall-cmd --zone=trusted --add-interface=waydroid0 --permanent >/dev/null 2>&1 || true
        firewall-cmd --zone=trusted --add-masquerade --permanent >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1 || true
        log_success 'Firewalld rules verified.'
    elif command -v ufw >/dev/null 2>&1 && systemctl is-active --quiet ufw; then
        ufw allow in on waydroid0 >/dev/null 2>&1 || true
        ufw route allow in on waydroid0 >/dev/null 2>&1 || true
        log_success 'UFW rules verified.'
    fi
}

run_addons() {
    if ask_yes 'Execute casualsnek waydroid_script (Libhoudini/Magisk)?'; then
        TEMP_DIR=$(mktemp -d)
        chmod 0755 "$TEMP_DIR"
        git clone https://github.com/casualsnek/waydroid_script "$TEMP_DIR"
        python3 -m venv "$TEMP_DIR/venv"
        "$TEMP_DIR/venv/bin/pip" install -U pip wheel >/dev/null 2>&1
        "$TEMP_DIR/venv/bin/pip" install -r "$TEMP_DIR/requirements.txt" >/dev/null
        (cd "$TEMP_DIR" && "$TEMP_DIR/venv/bin/python" main.py)
    fi
}

main() {
    if [ -f /etc/NIXOS ] || command -v nix &>/dev/null; then
        if ! command -v waydroid &>/dev/null; then
            log_info "NixOS detected. Waydroid requires declarative configuration."
            echo ""
            printf "%sTo enable Waydroid on NixOS:%s\n" "$C_GREEN" "$C_RESET"
            printf "  1. Add to /etc/nixos/configuration.nix: %svirtualisation.waydroid.enable = true;%s\n" "$C_BLUE" "$C_RESET"
            printf "  2. Run: %ssudo nixos-rebuild switch%s\n\n" "$C_BLUE" "$C_RESET"
            log_info "This sets up kernel binder, container bridges, and waydroid-container service cleanly."
            exit 0
        fi
    fi

    trap cleanup EXIT
    if [[ -z "${WAYDROID_SETUP_RUNNING:-}" ]]; then
        ask_yes 'Proceed with Waydroid installation?' || exit 0
    fi

    verify_environment "$@"

    local pair sys_source ven_source updated=0
    if ! pair=$(discover_images "$REAL_HOME/Downloads" "$REAL_HOME"); then
        pair=$(prompt_for_images)
    fi
    read -r sys_source ven_source <<< "$pair"

    stage_images "$sys_source" "$ven_source"
    if install_images; then
        updated=1
        log_success 'Fresh images installed to destination.'
    else
        log_success 'Destination images already match staged files.'
    fi

    local state needs_init refresh
    state=$(configure_waydroid)
    read -r needs_init refresh <<< "$state"
    if (( needs_init )) || [[ -e "$WORK_DIR/.setup-init-pending" || -e "$DEST_DIR/.setup-init-pending" ]]; then
        systemctl stop "$SERVICE" 2>/dev/null || true
        : > "$WORK_DIR/.setup-init-pending" 2>/dev/null || true
        log_info 'Initializing Waydroid with the local image pair...'
        waydroid init --force --images_path "$DEST_DIR"
    elif (( refresh )); then
        systemctl stop "$SERVICE" 2>/dev/null || true
        log_info 'Refreshing configuration without downloading images or resetting overlays...'
        waydroid upgrade --offline
    else
        log_success 'Existing initialization and multi-window configuration reused.'
    fi

    state=$(configure_waydroid)
    [[ "$state" == '0 0' ]] || log_error 'Waydroid initialization or multi-window configuration is incomplete.'
    rm -f -- "$WORK_DIR/.setup-init-pending" "$DEST_DIR/.setup-init-pending" 2>/dev/null || true

    configure_firewall
    run_addons
    systemctl enable --now "$SERVICE" 2>/dev/null || true
    log_success 'Waydroid setup complete.'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
