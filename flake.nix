{
  description = "Dusky on NixOS — Pure, reproducible, debloated Hyprland desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # Exportable NixOS Modules for consumers
      nixosModules = {
        default = import ./modules/default.nix;
        packages = import ./modules/packages.nix;
        desktop = import ./modules/desktop.nix;
        dusky-run = import ./modules/dusky-run.nix;
        updater = import ./modules/updater.nix;
      };

      # Standalone Full NixOS System Configuration
      nixosConfigurations = {
        dusky-nix = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hardware-configuration.nix
            ./configuration.nix
          ];
        };
        default = self.nixosConfigurations.dusky-nix;
      };

      # Runnable apps (nix run github:Ubaidullah-Web-Dev/Dusky-on-NixOS#install)
      apps.${system} = {
        install = {
          type = "app";
          program = "${self.packages.${system}.installer}/bin/dusky-install";
        };
        default = self.apps.${system}.install;
      };

      # Packages
      packages.${system} = {
        installer = pkgs.writeShellScriptBin "dusky-install" ''
          exec ${pkgs.bash}/bin/bash ${./install.sh} "$@"
        '';
        default = self.packages.${system}.installer;
      };
    };
}
