# Dusky on NixOS — Documentation Hub

Welcome to the official documentation for **Dusky on NixOS**.

Whether you are starting from a completely blank drive with an official NixOS ISO or adding Dusky on top of an existing NixOS installation, these guides will walk you through every step in plain English with exact commands.

---

## 📖 Table of Contents

### 1. Installation Guides
* [**Minimal ISO Installation (Command Line)**](installation-minimal-iso.md)  
  *Step-by-step guide starting from the NixOS Minimal ISO. Covers Wi-Fi setup via CLI (`wpa_cli` / `iwctl`), disk partitioning, filesystem formatting, base installation, and deploying Dusky.*
* [**Graphical ISO Installation (GUI / Calamares)**](installation-graphical-iso.md)  
  *Beginner-friendly guide using the NixOS Graphical ISO (GNOME or Plasma) with a mouse-driven installer, graphical Wi-Fi selector, and automatic disk partitioning before layering Dusky on top.*
* [**Installing Dusky on Existing NixOS**](dusky-installation.md)  
  *Already running NixOS? Learn how to clone Dusky, deploy the system flake, sync dotfiles, and run the 78 automated ORCHESTRA setup steps.*

### 2. Post-Installation & Everyday Use
* [**Post-Installation Guide & Everyday Usage**](post-install-guide.md)  
  *Explore your new desktop: essential keybindings, navigating the Control Center, switching wallpapers and Waybar styles with Matugen, using the `s` script selector, and managing packages via `pkg`.*

### 3. Help & Troubleshooting
* [**Troubleshooting & FAQ**](troubleshooting.md)  
  *Quick solutions for common issues: live ISO Wi-Fi troubles, UEFI bootloader entries, Nvidia graphics setup, audio configurations, and display scaling.*

---

## 🎯 Which Installation Method Should You Choose?

| Scenario | Recommended Guide | Why? |
| :--- | :--- | :--- |
| **You want the simplest, easiest install** | [Graphical ISO Guide](installation-graphical-iso.md) | Connect to Wi-Fi with one click, partition disks visually with Calamares, and open a terminal to install Dusky. |
| **You prefer a pure, lightweight terminal workflow** | [Minimal ISO Guide](installation-minimal-iso.md) | Full control over your disk partitions, mount flags, and packages with zero intermediate desktop bloat. |
| **You already have a working NixOS setup** | [Dusky Installation Guide](dusky-installation.md) | Just clone the repo and run `./install.sh`. |

---

## 💡 Quick Tips Before You Begin
1. **Back up your data**: Installing an OS can erase drive contents if you choose to repartition. Double-check your disk labels (`lsblk`) before formatting!
2. **Use Ventoy or dd**: Writing the NixOS ISO to a USB drive is easiest using [Ventoy](https://www.ventoy.net) or `dd if=nixos.iso of=/dev/sdX status=progress bs=4M`.
3. **Pre-built binary caches**: Dusky uses official NixOS channels and pre-compiled binaries (`cache.nixos.org`). You won't spend hours compiling software from source.
