#!/usr/bin/env python3
"""
Smart, Lightweight & Accurate Battery Estimator & Power Draw for Waybar.
Designed for hardware where EC doesn't expose current_now (e.g., HP EliteBook).
Uses:
  1. Instant SOC power from RAPL / powercap (responsive to user actions)
  2. Ground-truth platform drain from chemical charge drop (immune to cell voltage sag)
  3. Stable nominal voltage (11.55V) to eliminate false voltage-sag power spikes.
Outputs Waybar-compatible JSON.
"""

import sys
import os
import time
import json
import argparse

BAT_DIR = "/sys/class/power_supply/BAT0"
AC_DIR = "/sys/class/power_supply/AC"
RAPL_FILE = "/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj"

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
STATE_FILE = os.path.join(RUNTIME_DIR, "waybar_battery_estimator.json")

ICONS_DISCHARGING = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
ICON_CHARGING = ""
ICON_PLUGGED = ""

# HP EliteBook baseline platform power (display @ 50%, Wi-Fi, motherboard chipset)
PLATFORM_BASE_WATTS = 3.8

def read_sysfs_int(path, default=0):
    try:
        with open(path, "r") as f:
            return int(f.read().strip())
    except Exception:
        return default

def read_sysfs_str(path, default=""):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return default

def get_battery_raw():
    charge_now = read_sysfs_int(f"{BAT_DIR}/charge_now", 0)       # uAh
    voltage_now = read_sysfs_int(f"{BAT_DIR}/voltage_now", 0)     # uV
    charge_full = read_sysfs_int(f"{BAT_DIR}/charge_full", 0)     # uAh
    charge_design = read_sysfs_int(f"{BAT_DIR}/charge_full_design", 0)
    voltage_min_design = read_sysfs_int(f"{BAT_DIR}/voltage_min_design", 11550000) # uV
    status = read_sysfs_str(f"{BAT_DIR}/status", "Unknown")
    cycles = read_sysfs_int(f"{BAT_DIR}/cycle_count", 0)
    ac_online = read_sysfs_int(f"{AC_DIR}/online", 0)

    # Use nominal design voltage to calculate stable chemical energy (immune to cell voltage sag)
    v_nom = (voltage_min_design / 1e6) if voltage_min_design > 0 else 11.55
    voltage_live = (voltage_now / 1e6) if voltage_now > 0 else v_nom

    # True physical capacity relative to original design capacity
    if charge_design > 0 and charge_now > 0:
        capacity = min(100, int(round((charge_now / charge_design) * 100)))
    else:
        capacity = read_sysfs_int(f"{BAT_DIR}/capacity", 0)

    energy_wh = (charge_now * v_nom) / 1e6 if charge_now > 0 else (capacity / 100.0) * 53.0
    energy_full_wh = (charge_design * v_nom) / 1e6 if charge_design > 0 else 53.0

    limit_pct = min(100, int(round((charge_full / charge_design * 100)))) if (charge_design > 0 and charge_full > 0) else 100

    return {
        "charge_now": charge_now,
        "charge_full": charge_full,
        "charge_design": charge_design,
        "v_nom": v_nom,
        "voltage_live": voltage_live,
        "energy_wh": energy_wh,
        "energy_full_wh": energy_full_wh,
        "capacity": capacity,
        "status": status,
        "cycles": cycles,
        "ac_online": ac_online,
        "health": limit_pct,
        "limit_pct": limit_pct
    }

def read_rapl_uj():
    return read_sysfs_int(RAPL_FILE, 0)

def load_state():
    try:
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE, "r") as f:
                return json.load(f)
    except Exception:
        pass
    return {
        "last_status": "",
        "last_rapl_uj": 0,
        "last_rapl_time": 0.0,
        "history": [],
        "filtered_power_w": 0.0
    }

def save_state(state):
    try:
        tmp = STATE_FILE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(state, f)
        os.replace(tmp, STATE_FILE)
    except Exception:
        pass

def calculate_linear_regression_slope(history):
    n = len(history)
    if n < 2:
        return 0.0

    sum_t = sum(p["t"] for p in history)
    sum_e = sum(p["e"] for p in history)
    mean_t = sum_t / n
    mean_e = sum_e / n

    numerator = sum((p["t"] - mean_t) * (p["e"] - mean_e) for p in history)
    denominator = sum((p["t"] - mean_t) ** 2 for p in history)

    if denominator == 0:
        return 0.0

    return numerator / denominator

def estimate_power(bat, state, now):
    status = bat["status"]
    energy_wh = bat["energy_wh"]
    rapl_uj = read_rapl_uj()

    # 1. Instant SOC power from RAPL
    rapl_power_w = 0.0
    if rapl_uj > 0 and state.get("last_rapl_uj", 0) > 0:
        dt_rapl = now - state.get("last_rapl_time", 0.0)
        d_uj = rapl_uj - state.get("last_rapl_uj", 0)
        if 0.5 <= dt_rapl <= 30.0 and d_uj >= 0:
            rapl_power_w = d_uj / (dt_rapl * 1e6)

    state["last_rapl_uj"] = rapl_uj
    state["last_rapl_time"] = now

    instant_total_w = (rapl_power_w + PLATFORM_BASE_WATTS) if rapl_power_w > 0 else 7.5

    # 2. State change detection: clear history on AC plug/unplug
    if status != state.get("last_status"):
        state["history"] = []
        state["last_status"] = status
        state["filtered_power_w"] = instant_total_w

    history = state.get("history", [])

    # Record point if energy changed or if 8 seconds elapsed
    if not history or abs(history[-1]["e"] - energy_wh) > 0.005 or (now - history[-1]["t"]) >= 8.0:
        history.append({"t": now, "e": energy_wh})

    # Keep a sliding window of 180 seconds (3 minutes)
    history = [p for p in history if (now - p["t"]) <= 180.0]
    if len(history) > 30:
        history = history[-30:]
    state["history"] = history

    history_span = (history[-1]["t"] - history[0]["t"]) if len(history) >= 2 else 0.0

    # 3. Ground-truth battery drain calculation
    battery_derived_w = None
    if len(history) >= 3 and history_span >= 25.0:
        slope = calculate_linear_regression_slope(history)
        calc_w = abs(slope) * 3600.0
        # Realistic laptop power bounds: 3W to 45W
        if 3.0 <= calc_w <= 45.0:
            battery_derived_w = calc_w

    # 4. Blend instant responsiveness with battery ground truth
    if battery_derived_w is not None:
        target_power = 0.65 * battery_derived_w + 0.35 * instant_total_w
    else:
        target_power = instant_total_w

    # Smooth with Exponential Moving Average (EMA)
    prev_filtered = state.get("filtered_power_w", 0.0)
    if prev_filtered > 0:
        alpha = 0.25
        filtered_power = alpha * target_power + (1.0 - alpha) * prev_filtered
    else:
        filtered_power = target_power

    # Clamp to realistic bounds for this laptop
    filtered_power = max(4.0, min(50.0, filtered_power))

    state["filtered_power_w"] = filtered_power
    save_state(state)

    return filtered_power

def format_time(hours):
    if hours <= 0 or hours > 99:
        return "Unknown"
    total_mins = int(round(hours * 60))
    h = total_mins // 60
    m = total_mins % 60
    if h > 0:
        return f"{h} h {m:02d} min"
    return f"{m} min"

def generate_output(layout="vertical"):
    bat = get_battery_raw()
    now = time.time()
    state = load_state()
    power_w = estimate_power(bat, state, now)

    cap = bat["capacity"]
    status = bat["status"]
    ac_online = bat["ac_online"]
    energy_wh = bat["energy_wh"]
    energy_full_wh = bat["energy_full_wh"]
    health = bat["health"]
    cycles = bat["cycles"]
    voltage_live = bat["voltage_live"]

    limit_cap = bat.get("limit_pct", 100)
    charge_full = bat.get("charge_full", 0)
    charge_now = bat.get("charge_now", 0)

    is_plugged = ac_online == 1 or status in ("Full", "Not charging")
    is_charging = status == "Charging"
    is_discharging = status == "Discharging"

    is_at_limit = is_plugged and (
        status in ("Full", "Not charging") or
        (charge_full > 0 and charge_now >= (charge_full - 30000)) or
        (cap >= limit_cap and not is_charging)
    )

    # Icon selection
    icon_idx = min(len(ICONS_DISCHARGING) - 1, max(0, cap // 10))
    icon = ICONS_DISCHARGING[icon_idx]

    css_classes = []
    if is_charging:
        css_classes.append("charging")
        icon = ICON_CHARGING
    elif is_plugged:
        css_classes.append("plugged")
        icon = ICON_PLUGGED
    else:
        css_classes.append("discharging")

    if cap <= 20:
        css_classes.append("critical")
    elif cap <= 40:
        css_classes.append("warning")

    rate_str = f"{power_w:.1f} W"
    if is_discharging:
        hrs = energy_wh / power_w if power_w > 0.5 else 0
        time_str = format_time(hrs)
        status_line = f"Empty in {time_str} (Power Draw: {rate_str})"
    elif is_charging:
        energy_cap_wh = (charge_full * bat["v_nom"]) / 1e6 if charge_full > 0 else energy_full_wh
        rem_wh = max(0, energy_cap_wh - energy_wh)
        hrs = rem_wh / power_w if power_w > 0.5 else 0
        time_str = format_time(hrs)
        status_line = f"Full ({limit_cap}%) in {time_str} (Charging Rate: +{rate_str})"
    elif is_at_limit:
        status_line = f"Plugged In (Fully Charged at {limit_cap}% Limit)"
    else:
        status_line = f"{status} (Rate: {rate_str})"

    # Vertical bar formatting (centered text lines)
    power_int = int(round(power_w))
    if layout == "vertical":
        if is_at_limit:
            text = f"{icon}\n{cap}"
        elif is_charging:
            text = f"{icon}\n+{cap}\n{power_int}W"
        else:
            text = f"{icon}\n{cap}\n{power_int}W"
    else:
        if is_at_limit:
            text = f"{icon} {cap}%"
        elif is_charging:
            text = f"{icon} +{cap}% ({power_int}W)"
        else:
            text = f"{icon} {cap}% ({power_int}W)"

    tooltip = (
        f"{status_line}\n"
        f"Battery: {cap}% ({energy_wh:.1f} / {energy_full_wh:.1f} Wh)\n"
        f"Hardware Limit: {limit_cap}% (HP Battery Health Manager)\n"
        f"Voltage: {voltage_live:.2f} V • Cycles: {cycles}\n\n"
        f"LMB: Power Saver\n"
        f"RMB: Hypridle Settings"
    )

    data = {
        "text": text,
        "alt": f"{cap}%",
        "tooltip": tooltip,
        "class": " ".join(css_classes),
        "percentage": cap
    }

    return json.dumps(data)

def main():
    parser = argparse.ArgumentParser(description="Waybar Smart Battery Estimator")
    parser.add_argument("--horizontal", action="store_true", help="Horizontal text layout")
    args = parser.parse_args()

    layout = "horizontal" if args.horizontal else "vertical"
    print(generate_output(layout))

if __name__ == "__main__":
    main()
