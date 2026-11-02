#!/usr/bin/env python3
import os
import sys
# Redirect to NixOS native generation manager
script = os.path.expanduser('~/user_scripts/dusky_system/generations/dusky_generation_manager.py')
os.execv(sys.executable, [sys.executable, script] + sys.argv[1:])
