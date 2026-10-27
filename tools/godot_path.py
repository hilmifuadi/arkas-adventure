#!/usr/bin/env python3
"""Cari executable Godot (versi console) untuk skrip tools.

Urutan: variabel lingkungan GODOT, lalu build bawaan di folder induk repo
(`Godot_v4.7.2-stable_mono_win64`), lalu `godot` di PATH. Mengembalikan None bila tidak ada.
"""
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def find_godot():
    env = os.environ.get("GODOT")
    if env and Path(env).exists():
        return env
    for base in (ROOT.parent.parent, ROOT.parent):
        for exe in base.glob("Godot_v*/**/*_console.exe"):
            return str(exe)
    return shutil.which("godot")


if __name__ == "__main__":
    print(find_godot() or "")
