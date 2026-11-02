{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/packages.nix
    ./modules/dusky-run.nix
    ./modules/updater.nix
    ./modules/desktop.nix
  ];

  # Bootloader - UEFI systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "dusky-nix";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  # Time & Locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix Flakes & Experimental Features with Binary Caches
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "ubaid" "@wheel" ];
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    auto-optimise-store = true;
  };

  # Graphics & Wayland Acceleration (Required for Hyprland)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable Hyprland Compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Security & Polkit
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Audio via PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # XDG Desktop Portals
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # Virtual Machine Integration (QEMU & Duskyport)
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # OpenSSH Daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # User accounts
  users.users.ubaid = {
    isNormalUser = true;
    description = "Ubaid";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    initialPassword = "1122";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5WTAHd6ke8MksJg1REyinq/8j7nqMaP3xmuzMP/ZVV ubaid@workstation"
    ];
  };

  users.users.root = {
    initialPassword = "1122";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5WTAHd6ke8MksJg1REyinq/8j7nqMaP3xmuzMP/ZVV ubaid@workstation"
    ];
  };

  # Fonts needed for Dusky Wayland UI, Status bars & Terminals
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    atkinson-hyperlegible
    liberation_ttf
  ];

  nixpkgs.config.allowUnfree = true;

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.memoryPercent = 50;

  services.resolved.enable = true;

    system.activationScripts.binbash = ''
    mkdir -p /bin /usr/bin
    ln -sf ${pkgs.bashInteractive}/bin/bash /bin/bash
    ln -sf ${pkgs.bashInteractive}/bin/bash /usr/bin/bash
  '';

  system.stateVersion = "26.05";
}
