{ config, lib, pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./desktop.nix
    ./dusky-run.nix
    ./updater.nix
  ];

  # Graphics & Wayland Acceleration (Required for Hyprland)
  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };

  # Hyprland Compositor
  programs.hyprland = {
    enable = lib.mkDefault true;
    xwayland.enable = lib.mkDefault true;
  };

  # Pipewire Audio Ecosystem
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # Fonts
  fonts = {
    fontDir.enable = lib.mkDefault true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      atkinson-hyperlegible
      liberation_ttf
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
    ];
    fontconfig = {
      enable = lib.mkDefault true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font Mono" ];
        sansSerif = [ "Atkinson Hyperlegible" ];
        serif = [ "Liberation Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Performance Tuning
  zramSwap.enable = lib.mkDefault true;
  services.resolved.enable = lib.mkDefault true;
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
}
