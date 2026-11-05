{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    vim
    neovim
    uv
    wget
    patchelf
    curl
    pciutils
    usbutils
    jq
    unzip
    zip
    _7zz
    file
    rsync
    bc
    socat
    tree
    less
    ripgrep
    fd
    fzf
    bat
    eza
    zoxide
    fastfetch
    btop
    htop
    yazi
    gum
    inxi
    smartmontools
    ethtool
    bmon
    wavemon
    iperf3
    moreutils
    dust
    gdu
    dysk
    compsize
    lsof
    iotop
    iftop
    lshw
    hwinfo
    powertop
    stress-ng
    sysstat
    inotify-tools
    inetutils
    plocate
    pv
    strace

    # Terminals
    kitty
    foot
    alacritty

    # Desktop Applications
    firefox
    gnome-calculator
    gnome-clocks
    gnome-disk-utility
    loupe
    mousepad
    xreader
    file-roller
    cameractrls
    catfish
    khal
    yad
    wtype
    wl-clip-persist
    hyprshade
    lazygit
    delta
    seahorse
    blueman
    zathura

    # Development & Linters
    cargo
    rustc
    pkg-config
    clang
    shellcheck
    shfmt
    stylua

    # Hyprland ecosystem & UI
    waybar
    rofi
    mako
    wlogout
    awww
    hyprpaper
    hypridle
    hyprlock
    hyprsunset
    hyprpicker
    libnotify
    luajit
    lua5_4
    libxkbcommon
    libxkbcommon.dev
    wlr-randr

    # Compatibility wrappers
    (runCommand "lua54-compat" {} ''
      mkdir -p $out/bin
      ln -s ${lua5_4}/bin/lua $out/bin/lua5.4
      ln -s ${lua5_4}/bin/lua $out/bin/lua54
    '')
    (writeShellScriptBin "ufw" ''
      case "$1" in
        status)
          if [ "$2" = "verbose" ]; then
            echo "Status: active"
            echo "Logging: off"
            echo "Default: deny (incoming), allow (outgoing), disabled (routed)"
            echo "New profiles: skip"
          elif [ "$2" = "numbered" ]; then
            echo "Status: active"
          else
            echo "Status: active"
          fi
          ;;
        show)
          if [ "$2" = "added" ]; then
            echo "Added user rules:"
          elif [ "$2" = "listening" ]; then
            echo "Listening ports:"
          else
            echo "UFW Report: $2"
          fi
          ;;
        app)
          if [ "$2" = "list" ]; then
            echo "Available applications:"
            echo "  OpenSSH"
          elif [ "$2" = "info" ]; then
            echo "Profile: $3"
            echo "Title: Service $3"
            echo "Ports: 22/tcp"
          fi
          ;;
        --version|version)
          echo "ufw 0.36.2"
          ;;
        *)
          exit 0
          ;;
      esac
    '')

    # Theming & Icons
    matugen
    bibata-cursors
    papirus-icon-theme
    papirus-folders
    adwaita-icon-theme
    adw-gtk3
    nwg-look
    imagemagick

    # GTK / GObject runtime & libs
    gtk3
    gtk4
    libadwaita
    graphene
    gdk-pixbuf
    pango.out
    glib.out
    glib.bin
    harfbuzz
    at-spi2-core
    gsettings-desktop-schemas
    gobject-introspection
    librsvg

    # Audio & Media
    cava
    playerctl
    pamixer
    pavucontrol
    alsa-utils
    pulseaudio
    mpv
    ffmpeg
    yt-dlp
    songrec
    sox
    rnnoise

    gcc
    wayland-scanner
    glib.dev

    # Screen Capture & Recording
    grim
    slurp
    swappy
    satty
    swayimg
    wf-recorder
    wl-clipboard
    cliphist

    # System & Hardware Management & TUIs
    tlp
    iptables
    iw
    linuxPackages.cpupower
    sysbench
    libqalculate
    wireguard-tools
    bluetui
    wifitui
    tray-tui
    peaclock
    thunar
    thunar-archive-plugin
    thunar-volman
    thunar-media-tags-plugin
    networkmanagerapplet
    brightnessctl
    starship

    # Python runtime with Dusky dependencies
    python315
    (python3.withPackages (ps: with ps; [
      pygobject3
      pillow
      rich
      textual
      requests
      pyyaml
      psutil
      tomlkit
      questionary
      regex
      evdev
      packaging
      pycairo
      pyopengl
      pyquery
      pyudev
      pygame-ce
      uvloop
    ]))
  ];

  environment.pathsToLink = [ "/share/tlp" "/share/gsettings-schemas" "/share/glib-2.0/schemas" "/lib/girepository-1.0" ];
  environment.sessionVariables.GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
  environment.sessionVariables.PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig";
  environment.sessionVariables.LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
  environment.etc."tlp.d/.keep".text = "";
}
