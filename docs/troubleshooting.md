# Troubleshooting & Frequently Asked Questions

This guide covers common issues encountered during installation or daily use of Dusky on NixOS, along with their tested solutions.

---

## 📶 Live ISO Wi-Fi & Networking

### Problem: Wi-Fi interface not showing up in `ip link`
1. Check if the wireless card is soft-blocked:
   ```bash
   rfkill list
   rfkill unblock all
   ```
2. Verify interface status:
   ```bash
   ip link set <interface-name> up
   ```

### Problem: `wpa_cli` says "Could not connect to wpa_supplicant"
Make sure the service is started:
```bash
systemctl restart wpa_supplicant
wpa_cli
```

### Problem: DNS resolution fails despite active Wi-Fi
If `ping 1.1.1.1` works but `ping google.com` fails, add a temporary nameserver:
```bash
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

---

## 💾 Installation & Memory Issues

### Problem: `Out of memory: Killed process (nix)` during `nixos-install`
In the live ISO, there is zero swap enabled by default. If your machine or VM has limited RAM, memory spikes during builds can trigger the kernel OOM killer:
`[ 2440.450011] Out of memory: Killed process 1689 (nix)`

**Solution (You do NOT need to re-download anything!):**
Nix is completely atomic and content-addressed. All packages already downloaded into `/mnt/nix/store` remain intact.

1. Enable a temporary swapfile on `/mnt`:
   ```bash
   sudo dd if=/dev/zero of=/mnt/swapfile bs=1M count=4096 status=progress
   sudo chmod 600 /mnt/swapfile
   sudo mkswap /mnt/swapfile
   sudo swapon /mnt/swapfile
   ```

2. Re-run `nixos-install`:
   ```bash
   sudo nixos-install --flake /mnt/etc/nixos#dusky-nix
   ```
   Nix will immediately detect all existing store paths in `/mnt/nix/store`, verify them, and resume directly from where it was interrupted.

---

## 🥾 Bootloader & UEFI

### Problem: Bootloader menu doesn't show up after reboot
* **Ensure UEFI mode**: Make sure your motherboard BIOS is configured to boot in **UEFI mode** with **Secure Boot disabled**.
* **EFI Partition Size**: The EFI partition must be formatted as **FAT32** with at least `512MB` (1GB recommended) mounted at `/boot`.
* **Re-install systemd-boot**:
  From the live ISO, mount your system and run:
  ```bash
  mount /dev/disk/by-label/nixos /mnt
  mount /dev/disk/by-label/BOOT /mnt/boot
  nixos-enter --root /mnt -c 'bootctl install'
  ```

---

## 🎮 Graphics & Monitors

### Nvidia GPU Setup
Dusky uses the Zen kernel and Wayland. If you have a dedicated Nvidia graphics card:
1. Open `/etc/nixos/configuration.nix`:
   ```bash
   sudo nano /etc/nixos/configuration.nix
   ```
2. Add the proprietary Nvidia driver:
   ```nix
   services.xserver.videoDrivers = [ "nvidia" ];
   hardware.nvidia = {
     modesetting.enable = true;
     powerManagement.enable = false;
     open = false; # Set to true if on RTX 2000-series or newer
     nvidiaSettings = true;
   };
   ```
3. Rebuild your system:
   ```bash
   sudo nixos-rebuild switch
   ```

### Custom Display Resolution or Scaling
To customize monitor layout, refresh rate, or scaling:
1. List connected monitors:
   ```bash
   hyprctl monitors
   ```
2. Edit your monitor configuration at `~/.config/hypr/edit_here/source/monitors.lua`:
   ```lua
   -- Example: 2560x1440 @ 144Hz with 1.0 scaling
   hl.monitor("DP-1, 2560x1440@144, 0x0, 1")
   
   -- Example: Laptop 4K display scaled at 1.5x
   hl.monitor("eDP-1, 3840x2160@60, 0x0, 1.5")
   ```
3. Reload Hyprland with `Super + Shift + R` or `hyprctl reload`.

---

## 🔊 Audio & Sound

### Problem: No sound output
1. Check if PipeWire and WirePlumber services are active:
   ```bash
   systemctl --user status pipewire wireplumber
   ```
2. Open the volume control panel:
   ```bash
   pavucontrol
   ```
   Go to the **Configuration** tab and ensure the correct audio profile (e.g., *Pro Audio* or *Analog Stereo Duplex*) is selected.
3. Unmute channels:
   ```bash
   wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
   wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%
   ```

---

## 🛡️ Rolling Back to a Previous Generation

The biggest advantage of NixOS is atomic generations. If an update or package causes an issue:

### At the Bootloader (Easiest)
1. Reboot your computer.
2. At the systemd-boot screen, select **NixOS - All Generations**.
3. Choose the previous working generation and press Enter.

### From the Running Desktop
Open a terminal and rollback instantly:
```bash
# Rollback system generation
sudo nix-env --rollback -p /nix/var/nix/profiles/system

# Or manage generations graphically in the Dusky Control Center (Super + C -> Generations)
```

---

## 📦 Running Standard Pre-compiled Linux Binaries (`nix-ld`)

Dusky includes **Nix-LD** configured by default in `modules/desktop.nix`.
This allows standard pre-compiled Linux binaries (downloaded tarballs, CLI utilities, games, or AppImages) to execute directly without running into `libGL.so` or `libc.so` missing errors.
