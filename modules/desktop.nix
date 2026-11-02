{ pkgs, ... }:

{
  # Greetd Display Manager with Tuigreet
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.hyprland}/bin/start-hyprland";
        user = "ubaid";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd ${pkgs.hyprland}/bin/start-hyprland";
        user = "greeter";
      };
    };
  };

  # Hyprlock PAM security integration
  programs.hyprlock.enable = true;

  # Global desktop session environment
  environment.sessionVariables = {
    GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
    LIBGL_ALWAYS_SOFTWARE = "1";
    XCURSOR_THEME = "Dusky";
    XCURSOR_SIZE = "20";
    HYPRCURSOR_THEME = "Dusky";
    HYPRCURSOR_SIZE = "20";
  };

  # DConf & Desktop Schemas
  programs.dconf.enable = true;

  # ZSH & Starship
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
  programs.starship.enable = true;

  # Shell defaults
  users.defaultUserShell = pkgs.zsh;
  users.users.root.shell = pkgs.zsh;
  users.users.ubaid.shell = pkgs.zsh;

  # Thunar Volume Manager & File Sharing
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;

  # Security Polkit Agent
  systemd.user.services.polkit-kde-agent = {
    description = "Polkit KDE Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Dynamic linker shim for standard Linux binaries (e.g. dusky-papers)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      glibc
      wayland
      libxkbcommon
      vulkan-loader
      libGL
      mesa
      fontconfig
      freetype
    ];
  };
}
