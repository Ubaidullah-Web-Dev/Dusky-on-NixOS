<div align="center">

```
  ██████╗ ██╗   ██╗███████╗██╗  ██╗██╗   ██╗     ███╗   ██╗██╗██╗  ██╗
  ██╔══██╗██║   ██║██╔════╝██║ ██╔╝╚██╗ ██╔╝     ████╗  ██║██║╚██╗██╔╝
  ██║  ██║██║   ██║███████╗█████═╝  ╚████╔╝█████╗██╔██╗ ██║██║ ╚███╔╝ 
  ██║  ██║██║   ██║╚════██║██╔═██╗   ╚██╔╝ ╚════╝██║╚██╗██║██║ ██╔██╗ 
  ██████╔╝╚██████╔╝███████║██║  ██╗   ██║        ██║ ╚████║██║██╔╝ ██╗
  ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝        ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
```

### The Pure, Declarative & Reproducible Hyprland Desktop for NixOS

[![NixOS](https://img.shields.io/badge/NixOS-26.11%20unstable-blue?logo=nixos&logoColor=white)](https://nixos.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-0.57-teal?logo=hyprland&logoColor=white)](https://hyprland.org)
[![ORCHESTRA](https://img.shields.io/badge/ORCHESTRA-78%2F78%20Passed-brightgreen)](nix_setup_scripts/ORCHESTRA.sh)
[![License](https://img.shields.io/badge/License-GPLv3-orange.svg)](LICENSE)
[![Zero Bloat](https://img.shields.io/badge/Debloated-Zero%20QS%20%2F%20Pure%20Dusky-purple)]()

[**Quick Install**](#quick-installation) · [**Features**](#features) · [**Arch vs NixOS**](#dusky-on-arch-vs-dusky-on-nixos) · [**ORCHESTRA**](#master-orchestrator) · [**Directory Structure**](#repository-structure)

</div>

---

## Overview

**Dusky on NixOS** is the standalone, reproducible NixOS port of [**Dusky**](https://github.com/dusklinux/dusky). 

Built from the ground up for purity and performance, this repository combines:
1. **A Complete NixOS Flake & System Architecture** — Declarative system packages, Gtk4/Libadwaita desktop integration, Greetd display manager, ZRAM memory compression, and automated update/rollback utilities.
2. **The Dusky Master Orchestrator (`ORCHESTRA.sh`)** — A battle-tested suite of **78 automated setup scripts** completely ported and validated for NixOS.
3. **Pure Dusky Rice** — Hyprland 0.57, Waybar (20 modular switcher styles), Rofi launcher with 43 Dusky Terminal User Interfaces (TUIs), Hyprlock security, and Matugen wallpaper-adaptive dynamic colors.
4. **Zero Bloat & Zero Compilation** — 100% pre-compiled packages directly from official binary caches (`cache.nixos.org` and `hyprland.cachix.org`). No Quickshell overhead, no heavy webview layers.

---

## Features

- **Hyprland 0.57 Wayland Compositor**: Hardware accelerated, smooth animations, dynamic window rules, and keybinding cheatsheets.
- **20 Modular Waybar Styles**: Switch dynamically between horizontal, vertical, circular, compact, notch, and minimal themes.
- **43 Native Dusky TUIs**: System monitor, disk I/O, audio visualizer, wallpaper selector, DNS switcher, clipboard persistence manager, and firewall control integrated right into Rofi.
- **Hyprlock Lockscreen**: Modern, sleek screen locker integrated with PAM authentication.
- **Matugen Dynamic Theming**: Real-time extraction of 16-color Material 3 palettes from active wallpapers for Waybar, Rofi, Kitty, Foot, Alacritty, and GTK.
- **Managed Background Daemons**:
  - `dusky_clipboard.service`: Seamless persistent clipboard backend with RAM and disk storage modes (`wl-clip-persist`).
  - `dusky.service`: Fast GTK4 / Libadwaita Dusky Control Center daemon.
  - `network_meter.service`: Real-time Waybar bandwidth and packet monitoring.
- **Declarative System Management**:
  - `dusky-update`: One-command flake update, git sync, and system generation rebuild.
  - `dusky-rollback`: Instant one-command generation rollback.
  - `dusky-run`: Cgroup-scoped app launcher with OOM-score protection.

---

## Dusky on Arch vs Dusky on NixOS

<table>
  <thead>
    <tr>
      <th width="50%">Dusky on Arch Linux</th>
      <th width="50%">Dusky on NixOS</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>Package Management:</b> Pacman + Paru / Yay AUR helper</td>
      <td><b>Package Management:</b> Declarative Nix Flakes & Nixpkgs</td>
    </tr>
    <tr>
      <td><b>Stability:</b> Rolling release; susceptible to package drift</td>
      <td><b>Stability:</b> Atomic generations with instantaneous rollback</td>
    </tr>
    <tr>
      <td><b>Setup Engine:</b> Arch setup scripts targeting root directories</td>
      <td><b>Setup Engine:</b> NixOS modules + 78/78 passing Nix-adapted scripts</td>
    </tr>
    <tr>
      <td><b>System Services:</b> Imperative systemd unit enabling</td>
      <td><b>System Services:</b> Declarative systemd & user unit definitions</td>
    </tr>
    <tr>
      <td><b>Desktop Parity:</b> 100% pure Dusky rice</td>
      <td><b>Desktop Parity:</b> 100% pure Dusky rice, identical visuals & TUIs</td>
    </tr>
  </tbody>
</table>

---

## Quick Installation

### Option 1: Automated Standalone Installer (Recommended)

Run the automated installer on any existing NixOS system:

```bash
git clone https://github.com/Ubaidullah-Web-Dev/Dusky-on-NixOS.git ~/Dusky-on-NixOS
cd ~/Dusky-on-NixOS
bash install.sh
```

To run non-interactively in Autonomous Mode:
```bash
bash install.sh --yes
```

---

### Option 2: Nix Flake Deployment

Switch your NixOS system directly to Dusky using flakes:

```bash
sudo nixos-rebuild switch --flake github:Ubaidullah-Web-Dev/Dusky-on-NixOS#dusky-nix
```

---

### Option 3: Consuming as a Flake Module

If you already manage your system with your own NixOS flake, you can add Dusky as an input:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dusky.url = "github:Ubaidullah-Web-Dev/Dusky-on-NixOS";
  };

  outputs = { self, nixpkgs, dusky, ... }: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        dusky.nixosModules.default
      ];
    };
  };
}
```

---

## Master Orchestrator

The heart of Dusky's configuration is `nix_setup_scripts/ORCHESTRA.sh`. It sequences 78 setup phases covering everything from font configuration to dynamic theme placement and audio sinks:

```bash
cd ~/user_scripts/nix_setup_scripts
./ORCHESTRA.sh
```

### Verified Steps Sequence (78 / 78 Passing)
1. Pre-generated color verification
2. Network connectivity validation
3. Dotfiles bootstrap deployment
4. Hyprland custom configuration setup
5. Hyprland core Lua generation
6. Default window animations
7. Declarative package verification
8. Matugen state placement
9. Default Thunar terminal binding
10. Dusky `.desktop` menu generation (43 TUIs)
11. Keyboard layout configuration
12. Sleep & hypridle timeout provisioning
13–21. Declarative system service & shell verification
22. PAM keyring greetd integration
23. Systemd D-Bus service synchronization
24. Battery notifier service configuration
25. Btrfs & snapper subvolume isolation
26. Dusky font configurator (`Atkinson Hyperlegible`, `Liberation Serif`, `JetBrains Mono`)
27. Matugen smart theming activation
28. Matugen directories creation
29. Dusky papers thumbnail cache initialization
30. Blur, shadow, and opacity presets
31. Theme control (`theme_ctl.py`)
32. Qt5 / Qt6 platform theme integration
33. Udev USB notification service
34. Terminal defaults selector
35–44. ZRAM swap configuration, THP optimizer, & systemd accounting
45–48. Default applications selector (browser, editor, terminal, file manager)
49–51. Thunar, Mousepad, and bookmarks sidepane configurations
52. Dusky service toggler
53. Git global defaults configuration
54. GTK root symlinking
55. Systemd resolved DNS configuration
56. Obsidian / notes configuration
57. Nix / system cache purge
58. Installation cleanup
59. Bibata modern cursor theme
60. Color generation for current wallpaper
61–63. GPU hardware acceleration detection & configuration
64. Dusky Wayland clipboard persistence daemon setup
65. Intel media SDK acceleration validation
66. Firefox Dusky sites integration
67. Waybar modular configuration switcher
68. MPV hardware video player setup
69–71. WayClick soundpack installer & key sound setup
72. Battery notification thresholds
73. Hyprland dynamic reload
74. User groups provisioning
75. Power management and idle recovery
76. Dusky commands fleet orchestrator
77. Sudoers passwordless configuration
78. Wallpaper selector thumbnail cache generator

---

## Repository Structure

```
.
├── flake.nix                       # Top-level flake exports (nixosConfigurations, nixosModules, apps)
├── configuration.nix               # System-level configuration
├── hardware-configuration.nix      # Hardware definitions
├── install.sh                      # Universal interactive & autonomous installer
├── modules/                        # Declarative NixOS modules
│   ├── default.nix                 # Core module aggregating all subsystems
│   ├── packages.nix                # Complete package manifest, TUIs, & Python environment
│   ├── desktop.nix                 # Greetd, Hyprland, Polkit, & desktop settings
│   ├── dusky-run.nix               # Systemd cgroup & slice runner
│   └── updater.nix                 # Declarative updater and rollback scripts
├── nix_setup_scripts/              # Ported Dusky Orchestration Suite
│   ├── ORCHESTRA.sh                # Master orchestrator (78 steps)
│   ├── deploy_dotfiles.sh          # Dotfiles deployment bootstrap
│   └── scripts/                    # All 78 modular setup scripts
├── .config/                        # Dusky user configurations
│   ├── hypr/                       # Hyprland 0.57 configuration & Lua overlays
│   ├── waybar/                     # 20 modular Waybar themes
│   ├── rofi/                       # Rofi launcher, calculator, emoji, & themes
│   ├── desktop_entries/            # 70 application entries & 43 Dusky TUIs
│   ├── matugen/                    # Dynamic palette templates & color definitions
│   └── ...                         # Foot, Kitty, Alacritty, Mako, Kvantum, etc.
├── user_scripts/                   # Dusky system utilities & background daemons
│   ├── clipboard/                  # Dusky clipboard persistence daemon
│   ├── dusky_system/               # Dusky Control Center (GTK4/Libadwaita)
│   ├── waybar/                     # Waybar swapper & monitoring daemons
│   └── ...                         # TUIs, soundpacks, & system controls
├── Pictures/                       # Wallpapers & theme assets
│   ├── wallpapers/                 # Default wallpapers (dusk_default.jpg)
│   └── readme_assets/              # Visual preview assets
└── .zshrc                          # Dusky ZSH interactive prompt
```

---

## Built-In Utilities

| Utility | Command | Description |
| :--- | :--- | :--- |
| **System Updater** | `dusky-update` | Pulls latest changes, updates flake, and rebuilds the system. |
| **Instant Rollback** | `dusky-rollback` | Instantly rolls back to the previous NixOS generation. |
| **Scoped App Runner** | `dusky-run <command>` | Launches processes in dedicated systemd cgroups with OOM-kill protection. |
| **Clipboard Persist** | `dusky_clipboard_daemon.sh` | Retains Wayland clipboard content across application closures and reboots. |
| **Waybar Swapper** | `dusky_waybars.desktop` | Live GUI/TUI swapper between all 20 Waybar designs. |

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See [LICENSE](LICENSE) for details.

Developed with passion for the **Dusky Linux** and **NixOS** communities.
