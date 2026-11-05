{ pkgs, ... }:

let
  dusky-run = pkgs.writeShellScriptBin "dusky-run" ''
    set -euo pipefail

    export LIBGL_ALWAYS_SOFTWARE=1
    export GI_TYPELIB_PATH="/run/current-system/sw/lib/girepository-1.0"
    export LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib:/run/current-system/sw/lib''${LD_LIBRARY_PATH:+:''$LD_LIBRARY_PATH}"

    slice="app.slice"
    score=200
    preference="none"

    case "''${1-}" in
      --session)    slice="session.slice"; score=100; preference="avoid"; shift ;;
      --background) slice="background.slice"; score=300; preference="none"; shift ;;
      -h|--help)    echo "usage: dusky-run [--session|--background] command [args...]"; exit 0 ;;
    esac
    [[ "''${1-}" == "--" ]] && shift
    [[ $# -gt 0 ]] || exit 1

    raw_name="''${1##*/}"
    case "$raw_name" in
      waybar|mako|swaync|hypridle|hyprpaper|awww-daemon|wpaperd|hyprpolkitagent)
        slice="session.slice"
        score=100
        preference="avoid"
        ;;
    esac

    app_name="$(printf '%s' "$raw_name" | tr -cd 'a-zA-Z0-9_.-')"
    app_name="''${app_name:-app}"
    unit="app-''${app_name}-$$-$RANDOM"

    exec systemd-run --user --scope --slice="$slice" --unit="$unit" --collect --quiet \
      --setenv=LIBGL_ALWAYS_SOFTWARE=1 \
      --setenv=GI_TYPELIB_PATH="/run/current-system/sw/lib/girepository-1.0" \
      --setenv=LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib:/run/current-system/sw/lib''${LD_LIBRARY_PATH:+:''$LD_LIBRARY_PATH}" \
      --property=OOMPolicy=continue \
      --property=ManagedOOMPreference="$preference" \
      --property=MemoryAccounting=yes \
      -- "$@"
  '';
in
{
  environment.systemPackages = [ dusky-run ];
}
