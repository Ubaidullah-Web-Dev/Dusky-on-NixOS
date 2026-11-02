# Post-Installation Guide & Everyday Usage

Welcome to your new **Dusky on NixOS** desktop! This guide will help you get familiar with keybindings, desktop features, system management, and customization.

---

## ⌨️ Essential Keyboard Shortcuts

All keybindings use the **Super** key (the Windows or Command key).

### Application Launching & Windows
| Keybinding | Action |
| :--- | :--- |
| `Super + Return` | Launch default terminal (`foot`) |
| `Super + Space` | Application launcher (`rofi`) |
| `Super + C` | Open Dusky Control Center |
| `Super + W` | Dusky Papers (Wallpaper picker & dynamic theme generator) |
| `Super + E` | Open Thunar File Manager |
| `Super + Q` | Close focused window |
| `Super + F` | Toggle window fullscreen |
| `Super + V` | Toggle floating mode for active window |
| `Super + S` | Interactive User Scripts selector (`s` tool) |

### Workspaces & Navigation
| Keybinding | Action |
| :--- | :--- |
| `Super + 1 .. 9` | Switch to workspace 1 through 9 |
| `Super + Shift + 1 .. 9` | Move active window to workspace 1 through 9 |
| `Super + Left / Right` | Focus adjacent window |
| `Super + Shift + Left / Right` | Move active window directionally |
| `Super + Mouse Left Click` | Drag & move floating or tiled window |
| `Super + Mouse Right Click` | Resize window interactively |

### Session & System
| Keybinding | Action |
| :--- | :--- |
| `Super + L` | Lock screen (`hyprlock`) |
| `Super + Shift + E` | Power & logout menu (`wlogout`) |
| `PrintScreen` | Take screenshot (`grim` + `slurp`) |

---

## 🎛️ Dusky Control Center

Hit `Super + C` or type `dusky_control_center` in any terminal to open the **Control Center**.

From here, you can manage:
1. **System Generations**: View all system snapshots, switch to previous boot states, or remove old generations to free up disk space.
2. **Waybar Style Switcher**: Swap between 20+ horizontal, vertical, pill, or island Waybar designs with one click.
3. **Services TUI**: Toggle system and user services interactively (OpenSSH, WireGuard, Bluetooth, Audio DSP, battery thresholds, etc.).
4. **Appearance & Theming**: Switch font families, cursor sizes, and UI scaling on the fly.
5. **Optional Packages**: Install curated multimedia, dev tools, and utilities via `nix profile`.

---

## 🎨 Changing Wallpapers & Colors (Matugen)

Dusky features automatic Material You color extraction powered by **Matugen**.

1. Press `Super + W` to open **Dusky Papers**.
2. Browse through wallpapers with your arrow keys or search for keywords.
3. Press `Enter` to select a wallpaper.
4. **What happens automatically**:
   * The new wallpaper is applied to your desktop.
   * Matugen extracts the primary, secondary, tertiary, and accent palette.
   * Your Waybar, terminal colors, Rofi menus, window borders, and Mako notifications immediately update to match the wallpaper.

*To add your own wallpapers, simply drop `.jpg` or `.png` files into `~/Pictures/wallpapers`.*

---

## 📦 Package Management on NixOS

Dusky provides clean, fast tools for managing packages:

### 1. View Installed Profile Packages
Run the `pkg` alias:
```bash
pkg
```
This lists all user packages currently installed in your profile.

### 2. Search Available Packages
Run the `pkg_search` alias:
```bash
pkg_search
```
Or open the desktop app **Dusky Package Search** from Rofi. Type any query to find packages in Nixpkgs.

### 3. Install a Package for Your User
To install a standalone utility (e.g., `fastfetch`, `htop`, `vlc`):
```bash
nix profile add nixpkgs#vlc
```
To remove a package:
```bash
nix profile remove vlc
```

### 4. Add Permanent System Packages
To make a package available system-wide across all users and generations:
1. Edit `/etc/nixos/modules/packages.nix`:
   ```bash
   sudo nano /etc/nixos/modules/packages.nix
   ```
2. Add the package name inside the `environment.systemPackages` list.
3. Apply the changes:
   ```bash
   sudo nixos-rebuild switch
   ```

---

## 🔄 Updating Your System

Dusky includes an integrated updater that safely pulls repository improvements and updates your NixOS system:

* **From Terminal**: Run `update_dusky` or `~/user_scripts/update_dusky/update_dusky.sh`.
* **From Control Center**: Click the **Update System** button on the main page.
* **Waybar Indicator**: The update icon in Waybar (`` / `󰚰`) will notify you when updates are pending.
