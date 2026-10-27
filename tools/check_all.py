#!/usr/bin/env python3
"""Jalankan semua pemeriksaan statis (tanpa Godot): linter brief + validator data."""
import subprocess
import sys
from pathlib import Path

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
sys.exit(1 if failed else 0)
