#!/usr/bin/env python3
"""
Dusky NixOS Package Search Tool.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys

CLR_CYAN = "\033[1;36m"
CLR_GREEN = "\033[1;32m"
CLR_YELLOW = "\033[1;33m"
CLR_RED = "\033[1;31m"
CLR_BOLD = "\033[1m"
CLR_RESET = "\033[0m"

def main():
    if sys.stdout.isatty():
        print("\033[H\033[2J", end="")
    print(f"{CLR_CYAN}╔══════════════════════════════════════════════════════════════════════╗{CLR_RESET}")
    print(f"{CLR_CYAN}║                 {CLR_BOLD}DUSKY NIXOS PACKAGE SEARCH{CLR_RESET}{CLR_CYAN}                           ║{CLR_RESET}")
    print(f"{CLR_CYAN}╚══════════════════════════════════════════════════════════════════════╝{CLR_RESET}")
    print()
    print("Search available packages in Nixpkgs.")
    print()

    while True:
        try:
            query = input(f"{CLR_YELLOW}Enter package name or keyword to search (or 'q' to quit): {CLR_RESET}").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nExiting.")
            break

        if not query or query.lower() in ("q", "quit", "exit"):
            break

        print(f"\n{CLR_CYAN}Searching nixpkgs for '{query}'...{CLR_RESET}\n")
        try:
            # First try nix search
            subprocess.run(["nix", "--extra-experimental-features", "nix-command flakes", "search", "nixpkgs", query])
        except Exception as e:
            print(f"{CLR_RED}Search failed: {e}{CLR_RESET}")
        print()

if __name__ == "__main__":
    main()
