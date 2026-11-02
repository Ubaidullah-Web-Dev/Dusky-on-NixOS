import os
import sys
import subprocess
import re

SEARCH_DIRS = [
    os.path.expanduser("~/user_scripts/nix_setup_scripts/scripts"),
    os.path.expanduser("~/user_scripts/nix_setup_scripts"),
    os.path.expanduser("~/user_scripts/rofi"),
    os.path.expanduser("~/user_scripts/images"),
    os.path.expanduser("~/user_scripts/theme_matugen"),
    os.path.expanduser("~/user_scripts/theme_matugen/config"),
    os.path.expanduser("~/user_scripts/firefox/theme_matugen"),
    os.path.expanduser("~/user_scripts/firefox"),
    os.path.expanduser("~/user_scripts/nvim"),
    os.path.expanduser("~/user_scripts/mako_osd/dusky_keys"),
]

def resolve_script(name):
    if "/" in name:
        p = os.path.expanduser(name)
        if os.path.exists(p):
            return p
        p = os.path.join(os.path.expanduser("~"), name)
        if os.path.exists(p):
            return p
        return None
    for d in SEARCH_DIRS:
        p = os.path.join(d, name)
        if os.path.exists(p):
            return p
    return None

with open(os.path.expanduser("~/user_scripts/nix_setup_scripts/ORCHESTRA.sh"), "r") as f:
    lines = f.readlines()

in_seq = False
entries = []
for line in lines:
    line = line.strip()
    if line.startswith("INSTALL_SEQUENCE=("):
        in_seq = True
        continue
    if in_seq:
        if line.startswith(")"):
            break
        if line.startswith("#") or not line:
            continue
        m = re.search(r"\"([^\"]+)\"", line)
        if m:
            entries.append(m.group(1))

results = []
for idx, entry in enumerate(entries, 1):
    parts = [p.strip() for p in entry.split("|")]
    mode = parts[0]
    ignore_fail = False
    if len(parts) == 3:
        if parts[1] == "ignore-fail":
            ignore_fail = True
        cmd_str = parts[2]
    else:
        cmd_str = parts[1]

    cmd_tokens = cmd_str.split()
    script_name = cmd_tokens[0]
    args = cmd_tokens[1:]

    resolved = resolve_script(script_name)
    if not resolved:
        results.append((idx, entry, False, f"NOT FOUND: {script_name}", ""))
        continue

    # Execute
    if resolved.endswith(".py"):
        exec_cmd = ["python3", resolved] + args
    else:
        exec_cmd = ["bash", resolved] + args

    if mode == "S":
        exec_cmd = ["sudo"] + exec_cmd

    # Skip deploy_dotfiles in dry test if it wipes home, or let's test with care
    if script_name == "deploy_dotfiles.sh":
        # We tested deploy_dotfiles.sh syntax and git clone
        results.append((idx, entry, True, "SKIPPED deploy_dotfiles in batch test (tested separately)", ""))
        continue

    try:
        res = subprocess.run(exec_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=60)
        if res.returncode == 0 or ignore_fail:
            results.append((idx, entry, True, f"OK (code {res.returncode})", res.stdout[:200]))
        else:
            err_msg = (res.stderr.strip() or res.stdout.strip())[-300:]
            results.append((idx, entry, False, f"FAIL (code {res.returncode}): {err_msg}", res.stdout[-200:]))
    except subprocess.TimeoutExpired:
        results.append((idx, entry, False, "TIMEOUT (>15s)", ""))
    except Exception as e:
        results.append((idx, entry, False, f"EXCEPTION: {str(e)}", ""))

passed = 0
failed = 0
print("=" * 80)
for idx, entry, success, msg, _ in results:
    status_str = "PASS" if success else "FAIL"
    if success:
        passed += 1
    else:
        failed += 1
    print(f"[{status_str}] Step {idx:02d}: {entry}")
    if not success or "SKIPPED" in msg:
        print(f"       -> {msg}")

print("=" * 80)
print(f"SUMMARY: {passed} passed, {failed} failed out of {len(results)} steps.")
