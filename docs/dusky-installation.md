# Installing Dusky on an Existing NixOS System

If you already have a running NixOS installation and want to transform it into the full Dusky desktop environment, this guide covers both the **Automated Installer** and the **Manual Step-by-Step** method.

---

## ⚡ Method 1: Automated Installation (Recommended)

The easiest and safest way to install Dusky is using the included `install.sh` bootstrapper.

### 1. Clone the Repository
Open a terminal in your home directory:
```bash
nix-shell -p git
git clone https://github.com/Ubaidullah-Web-Dev/Dusky-on-NixOS.git ~/Dusky-on-NixOS
cd ~/Dusky-on-NixOS
```

### 2. Run the Installer
```bash
chmod +x install.sh
./install.sh
```

### 3. Choose Mode
Select Option **1** for the full experience:
1. **Full System Installation**: Deploys the system flake to `/etc/nixos`, backs up your existing `hardware-configuration.nix`, switches the system with `nixos-rebuild`, copies all dotfiles and scripts into `~/.config` and `~/user_scripts`, and runs the ORCHESTRA setup.
2. **Deploy Dotfiles & Run ORCHESTRA only**: Useful if you already manage `/etc/nixos` yourself and only want the desktop dotfiles, themes, and scripts.
3. **Deploy NixOS System Flake only**: Installs only the NixOS system configuration without copying dotfiles.

### 4. Reboot
```bash
sudo reboot
```

---

## 🛠️ Method 2: Manual Installation (For Power Users)

If you maintain your own custom NixOS configuration and want complete control over each step:

### Step 1: Preserve Your Hardware Configuration
Your current hardware configuration file contains disk UUIDs and kernel modules specific to your machine. Always keep it:
```bash
sudo cp /etc/nixos/hardware-configuration.nix /tmp/my-hardware.nix
```

### Step 2: Deploy Dusky Flake & Modules
Copy Dusky's flake, configuration, and modules into `/etc/nixos`:
```bash
sudo mkdir -p /etc/nixos/modules
sudo cp -f flake.nix /etc/nixos/
sudo cp -f flake.lock /etc/nixos/
sudo cp -f configuration.nix /etc/nixos/
sudo cp -rf modules/* /etc/nixos/modules/

# Restore your machine's unique hardware config
sudo cp -f /tmp/my-hardware.nix /etc/nixos/hardware-configuration.nix
```

### Step 3: Rebuild the System
Activate the new configuration:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#dusky-nix
```

### Step 4: Deploy Dotfiles & Wallpapers
Sync user configuration directories:
```bash
# Dotfiles
mkdir -p ~/.config
cp -rn .config/* ~/.config/ 2>/dev/null || true

# User scripts
mkdir -p ~/user_scripts
cp -rn user_scripts/* ~/user_scripts/ 2>/dev/null || true
mkdir -p ~/user_scripts/nix_setup_scripts
cp -rn nix_setup_scripts/* ~/user_scripts/nix_setup_scripts/ 2>/dev/null || true

# Wallpapers
mkdir -p ~/Pictures/wallpapers
cp -rn Pictures/* ~/Pictures/ 2>/dev/null || true

# Shell & local assets
cp -f .zshrc ~/.zshrc
[[ -d .local ]] && cp -rn .local/* ~/.local/ 2>/dev/null || true
```

### Step 5: Run ORCHESTRA Setup
Run the Dusky orchestrator to configure keyboard layouts, defaults, audio profiles, and color schemes:
```bash
chmod +x ~/user_scripts/nix_setup_scripts/ORCHESTRA.sh
~/user_scripts/nix_setup_scripts/ORCHESTRA.sh --profile 01_main
```

### Step 6: Reboot
```bash
sudo reboot
```

---

## 📂 Architecture Overview

Dusky on NixOS is structured into clean, modular Nix files:

| File / Module | Purpose |
| :--- | :--- |
| [`flake.nix`](../flake.nix) | Entry point defining Nixpkgs inputs, outputs, and system architecture. |
| [`configuration.nix`](../configuration.nix) | Main OS settings: Zen kernel (`linuxPackages_zen`), systemd-boot, PipeWire audio, and networking. |
| [`modules/desktop.nix`](../modules/desktop.nix) | Hyprland 0.57 setup, greetd autologin, Polkit KDE agent, Starship prompt, and `nix-ld` binary shim. |
| [`modules/packages.nix`](../modules/packages.nix) | Declarative package manifests (foot, rofi, waybar, matugen, btop, cava, etc.). |
| [`modules/updater.nix`](../modules/updater.nix) | Automated update checker and notification services. |
| [`modules/dusky-run.nix`](../modules/dusky-run.nix) | Helper environment wrappers. |
