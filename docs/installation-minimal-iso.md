# Installing Dusky from the NixOS Minimal ISO

This guide explains how to install a complete NixOS system with Dusky from scratch using the **NixOS Minimal Installation ISO**.

---

## 📋 Prerequisites & Preparation

1. **Download the ISO**:
   * Grab the latest **NixOS Minimal ISO (x86_64)** from the [official NixOS downloads page](https://nixos.org/download.html).
2. **Flash to USB Drive**:
   * **Linux**: `sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress oflag=sync` *(replace `/dev/sdX` with your USB drive)*.
   * **Cross-platform**: Use [Ventoy](https://www.ventoy.net) (just drag-and-drop the ISO) or [BalenaEtcher](https://etcher.balena.io).
3. **Boot into Live Media**:
   * Insert the USB drive, reboot your PC, and press your boot menu key (`F12`, `F11`, `F8`, or `Del`).
   * Boot the USB in **UEFI mode**. You will arrive at the root shell prompt (`root@nixos:~#`).

---

## 🌐 Step 1: Connecting to the Internet

You need an active internet connection to download packages.

### Option A: Wired Ethernet (Automatic)
If plugged into an Ethernet cable with DHCP, your network is usually active immediately. Verify:
```bash
ping -c 3 1.1.1.1
```
If you get replies, skip straight to **Step 2**.

---

### Option B: Wi-Fi via `wpa_supplicant` (Standard Minimal ISO)

1. Find your wireless interface name:
   ```bash
   ip link
   ```
   *(Look for an interface starting with `wlp` or `wlan0`)*.

2. Start the WPA supplicant service if it is not already running:
   ```bash
   systemctl start wpa_supplicant
   ```

3. Launch the interactive WPA control interface:
   ```bash
   wpa_cli
   ```

4. Inside the `wpa_cli` prompt, enter the following commands:
   ```text
   > scan
   OK
   > scan_results
   (Displays available networks)
   > add_network
   0
   > set_network 0 ssid "Your-WiFi-Name"
   OK
   > set_network 0 psk "Your-WiFi-Password"
   OK
   > enable_network 0
   OK
   > save_config
   OK
   > quit
   ```

5. Test the connection:
   ```bash
   ping -c 3 1.1.1.1
   ```

---

### Option C: Wi-Fi via `iwd` (`iwctl`)

Some NixOS live images support `iwd`. If available, it provides a very simple interface:

1. Launch `iwctl`:
   ```bash
   iwctl
   ```

2. Inside `iwctl`:
   ```text
   [iwd]# device list
   (Find your device name, e.g., wlan0)
   [iwd]# station wlan0 scan
   [iwd]# station wlan0 get-networks
   [iwd]# station wlan0 connect "Your-WiFi-Name"
   (Enter your password when prompted)
   [iwd]# exit
   ```

3. Test connection:
   ```bash
   ping -c 3 1.1.1.1
   ```

---

## 💾 Step 2: Disk Partitioning

Identify your destination disk:
```bash
lsblk
```
*NVMe drives typically show up as `/dev/nvme0n1`, while SATA SSDs/HDDs appear as `/dev/sda`.*

> [!CAUTION]
> The steps below will wipe the selected disk. Ensure you specify the correct drive letter/name!

### Recommended UEFI Partition Scheme:
* **Partition 1 (EFI Boot Partition)**: 1 GiB (FAT32, mount at `/boot`)
* **Partition 2 (Root Partition)**: Remaining space (Ext4 or Btrfs, mount at `/`)

### Using `cfdisk` (Easiest Interactive Tool):
```bash
cfdisk /dev/nvme0n1
```
1. Select **gpt** label type.
2. Create **New** partition:
   * Size: `1G`
   * Type: `EFI System`
3. Create **New** partition on the free space:
   * Size: Press Enter to use the rest of the disk
   * Type: `Linux filesystem`
4. Select **Write**, type `yes`, then **Quit**.

*(If you prefer a one-line command with `parted`):*
```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1024MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 1024MiB 100%
```

---

## 🔨 Step 3: Formatting and Mounting

Format the newly created partitions:

```bash
# Format the EFI partition
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1

# Format the Root partition (Ext4)
mkfs.ext4 -L nixos /dev/nvme0n1p2
```

Now, mount the partitions to `/mnt`:

```bash
# Mount root filesystem
mount /dev/disk/by-label/nixos /mnt

# Create and mount boot directory
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
```

Verify your mounts:
```bash
lsblk /dev/nvme0n1
```
You should see `/dev/nvme0n1p2` on `/mnt` and `/dev/nvme0n1p1` on `/mnt/boot`.

> [!TIP]
> **Virtual Machine or <= 8 GB RAM?**
> The minimal live ISO runs completely in RAM with no swap enabled. To prevent the Linux OOM (Out Of Memory) killer during builds, create a temporary swapfile on `/mnt`:
> ```bash
> dd if=/dev/zero of=/mnt/swapfile bs=1M count=4096 status=progress
> chmod 600 /mnt/swapfile
> mkswap /mnt/swapfile
> swapon /mnt/swapfile
> ```

---

## ⚙️ Step 4: Generating Hardware Configuration

Run NixOS's auto-detection tool:
```bash
nixos-generate-config --root /mnt
```
This generates:
* `/mnt/etc/nixos/configuration.nix`
* `/mnt/etc/nixos/hardware-configuration.nix`

---

## 🚀 Step 5: Installing Dusky and NixOS

You can install Dusky directly right now, saving you from setting up a temporary base system!

### 1. Enable Git and Flakes in the Live Shell:
```bash
nix-shell -p git
```

### 2. Clone the Dusky Repository:
```bash
git clone https://github.com/Ubaidullah-Web-Dev/Dusky-on-NixOS.git /tmp/dusky
```

### 3. Copy Dusky System Configuration to `/mnt/etc/nixos`:
```bash
# Backup the auto-generated configuration
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix

# Copy Dusky flake and modules into the target system
cp -f /tmp/dusky/flake.nix /mnt/etc/nixos/
cp -f /tmp/dusky/flake.lock /mnt/etc/nixos/
cp -f /tmp/dusky/configuration.nix /mnt/etc/nixos/
mkdir -p /mnt/etc/nixos/modules
cp -rf /tmp/dusky/modules/* /mnt/etc/nixos/modules/

# Restore your machine's exact hardware configuration
cp -f /tmp/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix
```

### 4. Run `nixos-install`:
```bash
nixos-install --flake /mnt/etc/nixos#dusky-nix
```
NixOS will now fetch all pre-built packages from the binary cache and configure the bootloader (`systemd-boot`).

### 5. Set Passwords for Root and User:
When prompted, set your root password. Then set the password for your main user (`ubaid` by default):
```bash
nixos-enter --root /mnt -c 'passwd ubaid'
```

---

## 📦 Step 6: Deploying User Configurations & First Boot

Before rebooting, copy the Dusky user scripts and configurations into your user's home directory:

```bash
mkdir -p /mnt/home/ubaid/.config
mkdir -p /mnt/home/ubaid/user_scripts
mkdir -p /mnt/home/ubaid/Pictures

# Copy dotfiles and user scripts
cp -rf /tmp/dusky/.config/* /mnt/home/ubaid/.config/
cp -rf /tmp/dusky/user_scripts/* /mnt/home/ubaid/user_scripts/
cp -rf /tmp/dusky/nix_setup_scripts /mnt/home/ubaid/user_scripts/
cp -rf /tmp/dusky/Pictures/* /mnt/home/ubaid/Pictures/
cp -f /tmp/dusky/.zshrc /mnt/home/ubaid/.zshrc
[[ -d /tmp/dusky/.local ]] && cp -rf /tmp/dusky/.local /mnt/home/ubaid/

# Fix ownership so your user owns the files
nixos-enter --root /mnt -c 'chown -R ubaid:users /home/ubaid'
```

---

## 🎉 Step 7: Reboot into Dusky!

Unmount and reboot:
```bash
umount -R /mnt
reboot
```

Remove your USB drive. Your machine will boot directly into **Hyprland** with greetd autologin, dynamic wallpaper themes, Waybar, and the full Dusky suite!
