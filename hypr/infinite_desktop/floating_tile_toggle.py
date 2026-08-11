#!/usr/bin/env python3
"""
floating_tile_toggle.py
Super+D: toggles between tiled and floating on the active workspace.
When going back to floating, restores each window to its previous position
(including negative coordinates from the infinite canvas).

Usage: python3 floating_tile_toggle.py
       (called from a bind in hyprland.lua)
"""

import subprocess
import json
import sys
import os
import fcntl

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (hyprctl_json, toggle_floating_lua, move_window_exact_lua,
                       resize_window_exact_lua, batch)

LOCK_FILE  = "/tmp/floating_tile_toggle.lock"
STATE_FILE = "/tmp/floating_tile_state.json"


# ──────────────────────────────────────────────
# State
# ──────────────────────────────────────────────

def load_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except Exception:
        return {}

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

def clear_state(workspace_id):
    state = load_state()
    state.pop(str(workspace_id), None)
    save_state(state)


# ──────────────────────────────────────────────
# Main logic
# ──────────────────────────────────────────────

def get_active_workspace():
    ws = hyprctl_json(["activeworkspace"])
    return ws["id"] if ws else None

def get_floating_windows(workspace_id):
    clients = hyprctl_json(["clients"]) or []
    return [
        w for w in clients
        if w.get("floating") and w.get("workspace", {}).get("id") == workspace_id
    ]

def get_tiled_windows(workspace_id, saved_addresses):
    """Windows that used to be floating (saved) and are now tiled."""
    clients = hyprctl_json(["clients"]) or []
    return [
        w for w in clients
        if not w.get("floating")
        and w.get("workspace", {}).get("id") == workspace_id
        and w["address"] in saved_addresses
    ]

def tile_floating_windows(workspace_id):
    """Saves positions and tiles all floating windows in the workspace."""
    windows = get_floating_windows(workspace_id)
    if not windows:
        print("No floating windows on the active workspace.")
        return False

    # Save positions and sizes indexed by address
    positions = {}
    for w in windows:
        positions[w["address"]] = {
            "x": w["at"][0],
            "y": w["at"][1],
            "w": w["size"][0],
            "h": w["size"][1],
            "class": w.get("class", ""),
            "title": w.get("title", ""),
        }

    state = load_state()
    state[str(workspace_id)] = positions
    save_state(state)

    print(f"Saved {len(positions)} windows. Tiling...")

    # Remove floating from all in a single batch
    exprs = [toggle_floating_lua(addr) for addr in positions]
    batch(exprs, timeout=5)

    return True

def restore_floating_windows(workspace_id):
    """Restores windows to floating and moves them to their saved positions."""
    state = load_state()
    positions = state.get(str(workspace_id))

    if not positions:
        print("No saved positions for this workspace.")
        return False

    # Get windows that need restoring
    tiled = get_tiled_windows(workspace_id, set(positions.keys()))

    if not tiled:
        clients = hyprctl_json(["clients"]) or []
        tiled = [
            w for w in clients
            if w.get("workspace", {}).get("id") == workspace_id
            and w["address"] in positions
        ]

    print(f"Restoring {len(tiled)} windows to floating...")

    # Step 1: togglefloating on all in a batch
    toggle_exprs = [toggle_floating_lua(w["address"]) for w in tiled if not w.get("floating")]
    if toggle_exprs:
        batch(toggle_exprs, timeout=5)

    # Step 2: move and resize all in a single batch
    move_exprs = []
    for w in tiled:
        addr = w["address"]
        pos = positions.get(addr)
        if not pos:
            continue
        x, y = pos["x"], pos["y"]
        w2, h2 = pos.get("w"), pos.get("h")
        move_exprs.append(move_window_exact_lua(x, y, addr))
        if w2 and h2:
            move_exprs.append(resize_window_exact_lua(w2, h2, addr))
        print(f"  ✓ {pos.get('class', addr)} -> ({x}, {y}) [{w2}x{h2}]")

    if move_exprs:
        batch(move_exprs, timeout=5)

    clear_state(workspace_id)
    return True


def is_tiled_state(workspace_id):
    """Determines whether the workspace is in tiled state (has saved positions)."""
    state = load_state()
    return str(workspace_id) in state


# ──────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────

def float_all_tiled(workspace_id):
    """Sets all tiled windows in the workspace to floating, without moving them."""
    clients = hyprctl_json(["clients"]) or []
    tiled = [
        w for w in clients
        if not w.get("floating")
        and w.get("workspace", {}).get("id") == workspace_id
    ]

    if not tiled:
        print("No tiled windows on the active workspace.")
        return False

    print(f"Setting {len(tiled)} windows to floating...")
    exprs = [toggle_floating_lua(w["address"]) for w in tiled]
    batch(exprs, timeout=5)

    return True


def main():
    # Lock file: if another instance is already running, exit silently
    lock_fd = open(LOCK_FILE, "w")
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("Another instance is already running, ignoring.")
        sys.exit(0)

    try:
        workspace_id = get_active_workspace()
        if workspace_id is None:
            print("Error: couldn't get the active workspace.")
            sys.exit(1)

        if is_tiled_state(workspace_id):
            # History exists -> restore positions
            restore_floating_windows(workspace_id)
        else:
            floating = get_floating_windows(workspace_id)
            if floating:
                # There are floating windows -> tile them and save positions
                tile_floating_windows(workspace_id)
            else:
                # No floating windows or history -> float all tiled ones
                float_all_tiled(workspace_id)
    finally:
        fcntl.flock(lock_fd, fcntl.LOCK_UN)
        lock_fd.close()

if __name__ == "__main__":
    main()
