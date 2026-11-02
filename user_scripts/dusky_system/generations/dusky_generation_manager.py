#!/usr/bin/env python3
"""
Dusky NixOS Generations & Rollback Manager.
Interactive TUI for viewing, switching, rolling back, and cleaning NixOS generations.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from dataclasses import dataclass

# ANSI colors
CLR_CYAN = "\033[1;36m"
CLR_GREEN = "\033[1;32m"
CLR_YELLOW = "\033[1;33m"
CLR_RED = "\033[1;31m"
CLR_MAGENTA = "\033[1;35m"
CLR_BOLD = "\033[1m"
CLR_RESET = "\033[0m"

@dataclass
class Generation:
    number: int
    date_str: str
    nixos_version: str
    kernel: str
    is_current: bool

def get_generations() -> list[Generation]:
    gens: list[Generation] = []
    try:
        out = subprocess.check_output(["nixos-rebuild", "list-generations"], text=True)
        lines = out.strip().splitlines()
        if len(lines) <= 1:
            return gens
        for line in lines[1:]:
            parts = line.split()
            if not parts:
                continue
            try:
                gen_num = int(parts[0])
                date_str = f"{parts[1]} {parts[2]}"
                nixos_ver = parts[3]
                kernel = parts[4]
                is_curr = parts[-1].lower() == "true" or "(current)" in line.lower()
                gens.append(Generation(gen_num, date_str, nixos_ver, kernel, is_curr))
            except Exception:
                continue
    except Exception as e:
        print(f"{CLR_RED}Error running nixos-rebuild list-generations: {e}{CLR_RESET}")
    return gens

def display_menu(gens: list[Generation]):
    os.system("clear")
    print(f"{CLR_CYAN}╔══════════════════════════════════════════════════════════════════════╗{CLR_RESET}")
    print(f"{CLR_CYAN}║             {CLR_BOLD}DUSKY NIXOS GENERATIONS & ROLLBACK MANAGER{CLR_RESET}{CLR_CYAN}               ║{CLR_RESET}")
    print(f"{CLR_CYAN}╚══════════════════════════════════════════════════════════════════════╝{CLR_RESET}")
    print()
    
    current_gen = next((g for g in gens if g.is_current), None)
    if current_gen:
        print(f"  {CLR_BOLD}Current Generation:{CLR_RESET} {CLR_GREEN}#{current_gen.number}{CLR_RESET} | Kernel: {CLR_GREEN}{current_gen.kernel}{CLR_RESET} | Built: {current_gen.date_str}")
    print()
    print(f"  {CLR_BOLD}{'Gen':<6} {'Build Date':<20} {'Kernel':<12} {'NixOS Version':<25} {'Status'}{CLR_RESET}")
    print(f"  {'─'*6} {'─'*20} {'─'*12} {'─'*25} {'─'*10}")
    
    for g in gens[:15]:
        cur_tag = f"{CLR_GREEN}★ CURRENT{CLR_RESET}" if g.is_current else ""
        print(f"  {CLR_CYAN}#{g.number:<5}{CLR_RESET} {g.date_str:<20} {g.kernel:<12} {g.nixos_version:<25} {cur_tag}")
    
    print()
    print(f"{CLR_CYAN}┌─── Actions ──────────────────────────────────────────────────────────┐{CLR_RESET}")
    print(f"{CLR_CYAN}│{CLR_RESET} [1] {CLR_BOLD}Rollback to Previous Generation{CLR_RESET}                                   {CLR_CYAN}│{CLR_RESET}")
    print(f"{CLR_CYAN}│{CLR_RESET} [2] {CLR_BOLD}Switch to Specific Generation Number{CLR_RESET}                          {CLR_CYAN}│{CLR_RESET}")
    print(f"{CLR_CYAN}│{CLR_RESET} [3] {CLR_BOLD}Garbage Collect (Delete Generations Older than 14 Days){CLR_RESET}       {CLR_CYAN}│{CLR_RESET}")
    print(f"{CLR_CYAN}│{CLR_RESET} [4] {CLR_BOLD}Optimise Nix Store (Deduplicate / Hardlink){CLR_RESET}                   {CLR_CYAN}│{CLR_RESET}")
    print(f"{CLR_CYAN}│{CLR_RESET} [q] {CLR_BOLD}Quit{CLR_RESET}                                                                 {CLR_CYAN}│{CLR_RESET}")
    print(f"{CLR_CYAN}└──────────────────────────────────────────────────────────────────────┘{CLR_RESET}")
    print()

def main():
    while True:
        gens = get_generations()
        display_menu(gens)
        try:
            choice = input(f"{CLR_YELLOW}Select an action [1-4, q]: {CLR_RESET}").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print("\nExiting.")
            break
            
        if choice in ("q", "quit", "exit"):
            print("Exiting.")
            break
        elif choice == "1":
            print(f"\n{CLR_YELLOW}Executing rollback...{CLR_RESET}")
            subprocess.run(["sudo", "nixos-rebuild", "switch", "--rollback"])
            input(f"\n{CLR_GREEN}Press Enter to continue...{CLR_RESET}")
        elif choice == "2":
            target = input(f"{CLR_YELLOW}Enter generation number to switch to: {CLR_RESET}").strip()
            if target.isdigit():
                gen_path = f"/nix/var/nix/profiles/system-{target}-link/bin/switch-to-configuration"
                if os.path.exists(gen_path):
                    print(f"\n{CLR_YELLOW}Switching to generation #{target}...{CLR_RESET}")
                    subprocess.run(["sudo", gen_path, "switch"])
                else:
                    print(f"\n{CLR_RED}Generation profile {gen_path} not found!{CLR_RESET}")
            else:
                print(f"{CLR_RED}Invalid generation number!{CLR_RESET}")
            input(f"\n{CLR_GREEN}Press Enter to continue...{CLR_RESET}")
        elif choice == "3":
            print(f"\n{CLR_YELLOW}Running nix-collect-garbage --delete-older-than 14d...{CLR_RESET}")
            subprocess.run(["sudo", "nix-collect-garbage", "--delete-older-than", "14d"])
            subprocess.run(["nix-collect-garbage", "--delete-older-than", "14d"])
            input(f"\n{CLR_GREEN}Press Enter to continue...{CLR_RESET}")
        elif choice == "4":
            print(f"\n{CLR_YELLOW}Running sudo nix-store --optimise...{CLR_RESET}")
            subprocess.run(["sudo", "nix-store", "--optimise"])
            input(f"\n{CLR_GREEN}Press Enter to continue...{CLR_RESET}")

if __name__ == "__main__":
    main()
