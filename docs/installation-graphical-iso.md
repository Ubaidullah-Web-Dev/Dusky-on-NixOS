# Installing Dusky from the NixOS Graphical ISO

If you prefer a friendly, point-and-click graphical installer to set up your partitions and Wi-Fi before layering Dusky on top, the **NixOS Graphical ISO** is the easiest route.

---

## 📋 Preparation

1. **Download the ISO**:
   * Visit the [official NixOS download page](https://nixos.org/download.html).
   * Download the **Graphical Live ISO (GNOME or Plasma desktop, x86_64)**.
2. **Flash to USB**:
   * Flash using [Ventoy](https://www.ventoy.net), [BalenaEtcher](https://etcher.balena.io), or `dd`.
3. **Boot into Live Desktop**:
   * Insert your USB drive, reboot your computer, and press your boot menu key (`F12`, `F11`, `F8`, etc.).
   * Select your USB in **UEFI mode**. You will land straight on the live desktop.

---

## 🌐 Step 1: Connect to Wi-Fi

1. Click the network / Wi-Fi icon in the top-right (GNOME) or bottom-right (Plasma) system tray.
2. Select your Wi-Fi network from the list.
3. Enter your password and click **Connect**.
4. Test by opening the browser or running `ping -c 3 1.1.1.1` in a terminal.

---

## 🖱️ Step 2: Run the Calamares Installer

On the live desktop, double-click the **Install NixOS** icon to open the Calamares installer.

1. **Welcome**: Select your language and click **Next**.
2. **Location**: Choose your region and city for timezone settings.
3. **Keyboard**: Pick your preferred keyboard layout and test it in the input box.
4. **Desktop Selection**: 
   * *Tip*: You can select **"No Desktop"** or keep the default (GNOME/Plasma). Dusky will replace it with lightweight Hyprland once installed.
5. **Partitions**:
   * **Erase disk**: The easiest option. Select your target drive from the dropdown, choose **"No swap"** (Dusky comes with optimized zram swap out of the box), and proceed.
   * **Manual partitioning**: If dual-booting, create a `1 GiB` FAT32 EFI partition mounted at `/boot` and an Ext4/Btrfs partition mounted at `/`.
6. **Users**:
   * Enter your name and username.
   * *Note*: If you set your username to `ubaid`, Dusky's default paths and configs work immediately without modifying `flake.nix`. If you choose a different username, you can easily adjust `flake.nix` during Step 3!
   * Choose a password. You can check *"Log in automatically without asking for password"* if desired.
7. **Install**:
   * Review the summary and click **Install Now**.
   * Calamares will partition your drive, generate `/etc/nixos/hardware-configuration.nix`, download base packages, and set up systemd-boot.
8. **Restart**: Once completed, check **Restart now** and click **Done**. Unplug the USB drive.

---

## 🚀 Step 3: Installing Dusky on Your Fresh System

After your computer reboots, log in and open a terminal (Press `Super` and search for "Terminal").

### 1. Enable Git (if not already installed):
```bash
nix-shell -p git
```

### 2. Clone the Dusky Repository:
```bash
git clone https://github.com/Ubaidullah-Web-Dev/Dusky-on-NixOS.git ~/Dusky-on-NixOS
cd ~/Dusky-on-NixOS
```

### 3. (Optional) Custom Username Adjustment:
If your username is not `ubaid`, edit `flake.nix` and `modules/desktop.nix` to match your username:
```bash
# If your username is 'alex', simply run:
sed -i 's/ubaid/alex/g' flake.nix modules/desktop.nix
```

### 4. Run the Master Installer:
```bash
chmod +x install.sh
./install.sh
```

You will be greeted with the Dusky installer banner and menu:
```text
Select Installation Mode:
1) Full System Installation (NixOS Flake + Dotfiles + ORCHESTRA) [Recommended]
2) Deploy Dotfiles & Run ORCHESTRA only
3) Deploy NixOS System Flake only
4) Exit
```
Press **Enter** (or type `1`) to run the Full Installation.

The installer will automatically:
* Deploy the Dusky Flake to `/etc/nixos` (preserving your machine's unique `hardware-configuration.nix`).
* Rebuild and switch the NixOS system to Hyprland 0.57 and the Zen kernel.
* Deploy all Dusky dotfiles (`~/.config/`), wallpapers (`~/Pictures/`), and user scripts (`~/user_scripts/`).
* Run the automated ORCHESTRA setup sequence.

---

## 🎉 Step 4: Reboot into Pure Dusky

When the installer finishes, reboot your system:
```bash
sudo reboot
```

Your system will boot directly into **Hyprland** managed by **greetd**, with instant wallpaper color theming, Waybar, fast terminal shortcuts, and the complete Dusky suite ready to use!
