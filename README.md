<div align="center">

```
  ██████╗ ██╗   ██╗███████╗██╗  ██╗██╗   ██╗     ███╗   ██╗██╗██╗  ██╗
  ██╔══██╗██║   ██║██╔════╝██║ ██╔╝╚██╗ ██╔╝     ████╗  ██║██║╚██╗██╔╝
  ██║  ██║██║   ██║███████╗█████═╝  ╚████╔╝█████╗██╔██╗ ██║██║ ╚███╔╝ 
  ██║  ██║██║   ██║╚════██║██╔═██╗   ╚██╔╝ ╚════╝██║╚██╗██║██║ ██╔██╗ 
  ██████╔╝╚██████╔╝███████║██║  ██╗   ██║        ██║ ╚████║██║██╔╝ ██╗
  ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝        ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
```

### The clean, snappy Hyprland experience from Dusky now natively built for NixOS.

[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue?logo=nixos&logoColor=white)](https://nixos.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-0.57-teal?logo=hyprland&logoColor=white)](https://hyprland.org)
[![License](https://img.shields.io/badge/License-GPLv3-orange.svg)](LICENSE)
[![Zero Compilation](https://img.shields.io/badge/Compiling-None%20%28Prebuilt%20Caches%29-brightgreen)]()

[**Quick Install**](#getting-started) · [**What's Inside**](#what-makes-this-special) · [**Keybinds**](#everyday-shortcuts) · [**Rollbacks & Updates**](#staying-updated--safe)

</div>

---

## Welcome to Dusky on NixOS

If you like how Dusky looks and feels on Arch the slick Waybar layouts, instant Material You colors extracted from your wallpapers, smooth Hyprland animations, and the massive collection of terminal tools — but you want it running reliably on NixOS with reproducible configs, atomic updates, and zero compiling from scratch, this setup is for you.

Everything here is configured declaratively with Nix flakes, uses pre-built binaries directly from official NixOS caches, and replaces traditional Arch tools (like pacman and snapper) with native Nix packages and system generations.

---

## What Makes This Special

- **Native Hyprland 0.57**: Ready out of the box with modern syntax, buttery window rules, and custom animations.
- **Dusky Papers (Wallpaper Picker)**: Hit `Super + W` to browse wallpapers. Selecting one instantly re-themes your desktop (Waybar, Rofi, terminal, borders) using Matugen color extraction.
- **20 Waybar Styles on Demand**: Don't like the current bar layout? Open the Waybar switcher from Rofi or Control Center and pick between top notch, circular, vertical, minimal, or full status designs in a single click.
- **Real NixOS Generations & Rollback**: No more dealing with brittle BTRFS snapshot managers or manual GRUB entries. Control Center includes a native generation manager to view, boot into, or delete old system states safely.
- **Fast & Lightweight**: Zero Quickshell or heavy web layers. It uses lightweight, responsive native utilities (`foot`, `kitty`, `rofi-wayland`, `libadwaita`, `mako`).
- **Zero Compilation Overhead**: Everything installs from binary caches (`cache.nixos.org`), so setting up takes minutes rather than hours of CPU burning.

---

## Getting Started

> [!TIP]
> **Installing from scratch?** Check our dedicated walkthroughs in the [`docs/`](docs/README.md) folder:
> * 🖥️ [**Minimal ISO Guide**](docs/installation-minimal-iso.md) — CLI Wi-Fi setup, manual disk partitioning, formatting, and installation.
> * 🖱️ [**Graphical ISO Guide**](docs/installation-graphical-iso.md) — Point-and-click Calamares installation.
> * 🛠️ [**Troubleshooting & FAQ**](docs/troubleshooting.md) — Wi-Fi, bootloader, Nvidia, and audio tips.

### 1. Requirements
- A fresh or existing installation of **NixOS** (unstable channel recommended).
- Git installed (`nix-shell -p git`).

### 2. Clone and Run Installer
Grab the repository and launch the interactive setup script:

```bash
git clone https://github.com/Ubaidullah-Web-Dev/Dusky-on-NixOS.git ~/Dusky-on-NixOS
cd ~/Dusky-on-NixOS
chmod +x install.sh
./install.sh
```

The installer gives you three options:
1. **Full Installation (Recommended)**: Deploys the system flake to `/etc/nixos`, builds the environment, copies dotfiles into your home directory, and runs the Dusky setup steps.
2. **Deploy Dotfiles & Scripts Only**: Best if you already have the flake installed and just want the updated configs.
3. **Deploy System Flake Only**: Deploys system packages and services to `/etc/nixos` without touching your user dotfiles.

Once the installer finishes, restart your machine to boot right into the new environment:
```bash
sudo reboot
```

---

## Everyday Shortcuts

| Key Combination | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Space</kbd> / <kbd>Alt</kbd> + <kbd>Space</kbd> | Open Application Launcher (Rofi) |
| <kbd>Super</kbd> + <kbd>Return</kbd> | Open Foot Terminal |
| <kbd>Super</kbd> + <kbd>W</kbd> / <kbd>Alt</kbd> + <kbd>4</kbd> | Open Dusky Papers (Wallpaper & Theme Selector) |
| <kbd>Super</kbd> + <kbd>E</kbd> | Open Thunar File Manager |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close Active Window |
| <kbd>Super</kbd> + <kbd>F</kbd> | Toggle Fullscreen |
| <kbd>Super</kbd> + <kbd>V</kbd> | Open Persistent Clipboard History |
| <kbd>Super</kbd> + <kbd>X</kbd> | Power & Session Menu |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Interactive Keybinding Search |
| <kbd>Super</kbd> + <kbd>1</kbd> - <kbd>9</kbd> | Switch Workspaces |

---

## Staying Updated & Safe

Because this setup runs on NixOS, updating your system or recovering from an issue is painless:

- **Update Everything**:
  Run `dusky-update` in your terminal. It pulls any changes from this repo, updates your flake inputs, and switches to the new generation cleanly.
- **Rollback If Something Breaks**:
  Run `dusky-rollback` to immediately switch back to the prior working generation, or select an earlier generation from the boot menu.
- **Manage Generations**:
  Open the Dusky Control Center, navigate to **System**, and open **NixOS Generations & Rollback** to prune old builds or optimize disk space.

---

## How It's Structured

```
.
├── flake.nix                       # System flake entrypoint
├── configuration.nix               # Base NixOS configuration
├── install.sh                      # User-friendly installer script
├── modules/                        # Modular Nix configs
│   ├── desktop.nix                 # Hyprland, Greetd, session vars, nix-ld
│   ├── packages.nix                # Desktop applications, TUIs & libraries
│   ├── updater.nix                 # dusky-update & dusky-rollback commands
│   └── dusky-run.nix               # Cgroup-isolated app runner
├── nix_setup_scripts/              # 78 automated setup scripts
│   └── ORCHESTRA.sh                # Main automated setup pipeline
├── .config/                        # User configurations
│   ├── hypr/                       # Hyprland 0.57 window rules & keybinds
│   ├── waybar/                     # 20 modular Waybar styles
│   ├── rofi/                       # App menus, emoji, and calculator
│   ├── desktop_entries/            # Custom application & TUI entries
│   └── matugen/                    # Material You dynamic palette engine
├── user_scripts/                   # Background daemons & Dusky utilities
│   ├── dusky_system/               # Control center & generation manager
│   ├── clipboard/                  # Persistent clipboard daemon
│   └── waybar/                     # Dynamic status bar swapper
└── .zshrc                          # Modular Zsh prompt with Starship & FZF
```

---

## License

Free and open-source under the [GNU General Public License v3.0](LICENSE).  
Built with love for the Linux and NixOS communities.
