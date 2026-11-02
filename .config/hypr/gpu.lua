-- -----------------------------------------------------------------
-- Hyprland GPU | Mode: AUTO | Primary: /dev/dri/card1
-- GPU: RedHat VirtIO | Red Hat, Inc. Virtio 1.0 GPU (rev 01) | 0000:00:02.0 | drv:virtio-pci
-- Gen: Python 3.14.6 + Rich + pyudev | systemd 261 | Hyprland 0.55.4+ Lua
-- DRM nodes shift per reboot - resolved via stable by-path
-- -----------------------------------------------------------------
local function resolve_card(pci_address, fallback)
 local cmd = "for d in /dev/dri/by-path/pci-"..pci_address.."*card; do [ -e \"$d\" ] && readlink -f \"$d\" 2>/dev/null && break; done"
 local h = io.popen(cmd)
 if h then
 local path = h:read("*l")
 h:close()
 if path and path ~= "" then return path end
 end
 return fallback
end

hl.env("AQ_DRM_DEVICES", resolve_card("0000:00:02.0", "/dev/dri/card1"))

-- Generic/VM (RedHat VirtIO) - by-path only
