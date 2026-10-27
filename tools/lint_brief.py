#!/usr/bin/env python3
"""Linter konsistensi brief untuk teks dan skrip game.

Memeriksa:
  - nama terlarang dari brief (mis. "Konoha") dan salah eja nama tokoh,
  - kata yang berisiko untuk anak-anak (peringatan),
  - setiap file teks "<area>.id.json" punya pasangan "<area>.en.json" dengan
    kunci dan placeholder {nama} yang sama, dan tidak ada teks kosong.

Pemakaian:  python tools/lint_brief.py [--strict]
Kode keluar 1 jika ada error (atau peringatan bila --strict).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEXT_DIRS = ["translations", "content"]
CODE_DIRS = ["system", "content", "main.gd", "world.gd"]
LANGS = ("id", "en")

FORBIDDEN = [
    (r"\bkonoha\b", 'Nama "Konoha" dilarang. Nama desa selalu "Desa Daun".'),
    (r"\b(hidden\s+)?leaf\s+village\b", 'Nama desa tidak diterjemahkan: tetap "Desa Daun".'),
    (r"\b(nadia|nadya|nadiah)\b", 'Salah eja: nama yang benar "Nadiya".'),
    (r"\b(farrah|farha)\b", 'Salah eja: nama yang benar "Farah".'),
    (r"\b(bhida|bidha)\b", 'Salah eja: nama yang benar "Bida".'),
    (r"\bhilmy\b", 'Salah eja: nama yang benar "Pak Hilmi".'),
]
CHILD_SAFETY = [
    (r"\b(darah|membunuh|bunuh|tewas|mayat|jenazah)\b", "Kata kurang ramah anak"),
    (r"\b(blood|kill|killed|murder|corpse)\b", "Kata kurang ramah anak"),
]
PLACEHOLDER = re.compile(r"\{(\w+)\}")


def rel(path):
    return path.relative_to(ROOT).as_posix()


def text_files():
    for name in TEXT_DIRS:
        base = ROOT / name
        if base.is_dir():
            yield from sorted(base.rglob("*.json"))


def lang_of(path):
    parts = path.name.split(".")
    return parts[-2] if len(parts) >= 3 and parts[-2] in LANGS else None


def code_files():
    for name in CODE_DIRS:
        p = ROOT / name
        if p.is_file():
            yield p
        elif p.is_dir():
            for pattern in ("*.gd", "*.tscn"):
                yield from sorted(p.rglob(pattern))


def check_text_pairs(errors):
    texts = {}
    for path in text_files():
        lang = lang_of(path)
        if not lang:
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{rel(path)}: JSON tidak valid ({exc})")
            continue
        if not isinstance(data, dict):
            errors.append(f"{rel(path)}: isi harus objek datar {{kunci: teks}}")
            continue
        base = path.with_name(".".join(path.name.split(".")[:-2]) + ".json")
        texts.setdefault(base, {})[lang] = (path, data)
    for base, by_lang in texts.items():
        for lang in LANGS:
            if lang not in by_lang:
                errors.append(f"{rel(base)}: tidak ada versi bahasa '{lang}'")
        if not all(lang in by_lang for lang in LANGS):
            continue
        id_path, id_data = by_lang["id"]
        en_path, en_data = by_lang["en"]
        for key in sorted(set(id_data) - set(en_data)):
            errors.append(f"{rel(en_path)}: kunci '{key}' belum diterjemahkan ke en")
        for key in sorted(set(en_data) - set(id_data)):
            errors.append(f"{rel(id_path)}: kunci '{key}' belum ada di id")
        for lang, (path, data) in by_lang.items():
            for key, value in data.items():
                if not isinstance(value, str) or not value.strip():
                    errors.append(f"{rel(path)}: kunci '{key}' kosong atau bukan teks")
        for key in set(id_data) & set(en_data):
            if set(PLACEHOLDER.findall(str(id_data[key]))) != set(PLACEHOLDER.findall(str(en_data[key]))):
                errors.append(f"{rel(en_path)}: placeholder '{key}' tidak sama dengan versi id")


def check_words(errors, warnings):
    texts = [p for p in text_files() if lang_of(p)]
    for path in texts + list(code_files()):
        # Kata ramah-anak hanya relevan untuk teks yang dibaca pemain, bukan nama kode.
        is_text = path in texts
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if "lint:ignore" in line:
                continue
            for pattern, message in FORBIDDEN:
                if re.search(pattern, line, re.IGNORECASE):
                    errors.append(f"{rel(path)}:{number}: {message}")
            for pattern, message in (CHILD_SAFETY if is_text else []):
                if re.search(pattern, line, re.IGNORECASE):
                    warnings.append(f"{rel(path)}:{number}: {message}: {line.strip()[:80]}")


def main():
    strict = "--strict" in sys.argv
    errors, warnings = [], []
    check_text_pairs(errors)
    check_words(errors, warnings)
    for message in warnings:
        print("PERINGATAN", message)
    for message in errors:
        print("ERROR", message)
    print(f"lint_brief: {len(errors)} error, {len(warnings)} peringatan")
    return 1 if errors or (strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
