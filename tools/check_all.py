#!/usr/bin/env python3
"""Jalankan semua pemeriksaan: linter brief, validator data, dan smoke test Godot.

Smoke test dilewati (dengan pemberitahuan) bila Godot tidak ditemukan; gunakan
`--no-godot` untuk melewatinya dengan sengaja atau set `GODOT=/path/ke/godot_console`.
"""
import subprocess
import sys
from pathlib import Path

from godot_path import ROOT, find_godot

HERE = Path(__file__).resolve().parent
STEPS = [
    ["lint_brief.py"],
    ["validate_data.py", "--self-test"],
    ["validate_data.py"],
]

failed = 0
for step in STEPS:
    print("==", " ".join(step))
    failed += subprocess.call([sys.executable, str(HERE / step[0])] + step[1:]) != 0

if "--no-godot" not in sys.argv:
    godot = find_godot()
    print("== smoke_test.gd")
    if godot:
        command = [godot, "--headless", "--path", str(ROOT), "--script", "tools/smoke_test.gd"]
        failed += subprocess.call(command) != 0
    else:
        print("Godot tidak ditemukan, smoke test dilewati (set GODOT=...).")
sys.exit(1 if failed else 0)
