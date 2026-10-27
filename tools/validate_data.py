#!/usr/bin/env python3
"""Validator data game (saat ini: puzzle matematika).

File data: content/**/puzzles.json, berisi daftar soal:
  {
    "id": "act01_gulungan",          # unik
    "act": 1,                         # 1..10
    "grade": 3,                       # 3..5 (kelas SD)
    "topic": "perkalian",
    "text": "PUZ_ACT01_GULUNGAN",     # kunci teks cerita
    "expr": "3*12+8",                 # perhitungan yang menghasilkan jawaban
    "answer": "44",                   # bilangan bulat, desimal (2.5) atau pecahan (3/4)
    "hints": ["..._H1", "..._H2", "..._H3"],
    "explanation": "..._EXPLAIN"
  }
Setiap kunci teks harus ada di bahasa id dan en. Jawaban dihitung ulang dari "expr".

Pemakaian:  python tools/validate_data.py            # validasi data nyata
            python tools/validate_data.py --self-test # uji validator sendiri
"""
import ast
import json
import operator
import sys
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ("id", "en")
REQUIRED = ("id", "act", "grade", "topic", "text", "expr", "answer", "hints", "explanation")
OPS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
}


def evaluate(expr):
    """Hitung ekspresi aritmetika dengan pecahan eksak (tanpa eval)."""
    def walk(node):
        if isinstance(node, ast.Expression):
            return walk(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return Fraction(str(node.value))
        if isinstance(node, ast.BinOp) and type(node.op) in OPS:
            return OPS[type(node.op)](walk(node.left), walk(node.right))
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
            return -walk(node.operand)
        raise ValueError(f"ekspresi tidak diizinkan: {ast.dump(node)}")
    return walk(ast.parse(expr, mode="eval"))


def parse_answer(text):
    return Fraction(str(text).strip())


def load_texts():
    keys = {lang: set() for lang in LANGS}
    for path in ROOT.rglob("*.json"):
        parts = path.name.split(".")
        if len(parts) >= 3 and parts[-2] in LANGS and ".godot" not in path.parts:
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                keys[parts[-2]].update(data)
    return keys


def validate_puzzles(puzzles, text_keys, where):
    errors = []
    seen = set()
    for index, puzzle in enumerate(puzzles):
        name = f"{where}[{index}]"
        missing = [field for field in REQUIRED if field not in puzzle]
        if missing:
            errors.append(f"{name}: field hilang: {', '.join(missing)}")
            continue
        name = f"{where}:{puzzle['id']}"
        if puzzle["id"] in seen:
            errors.append(f"{name}: id ganda")
        seen.add(puzzle["id"])
        if puzzle["act"] not in range(1, 11):
            errors.append(f"{name}: act harus 1..10")
        if puzzle["grade"] not in (3, 4, 5):
            errors.append(f"{name}: grade harus 3, 4, atau 5")
        if not isinstance(puzzle["hints"], list) or len(puzzle["hints"]) != 3:
            errors.append(f"{name}: harus ada tepat 3 petunjuk")
        keys = [puzzle["text"], puzzle["explanation"]] + list(puzzle["hints"])
        for lang in LANGS:
            for key in keys:
                if key not in text_keys[lang]:
                    errors.append(f"{name}: kunci teks '{key}' tidak ada di bahasa {lang}")
        try:
            computed = evaluate(puzzle["expr"])
            if computed != parse_answer(puzzle["answer"]):
                errors.append(f"{name}: jawaban '{puzzle['answer']}' != hasil expr {computed}")
        except (ValueError, SyntaxError, ZeroDivisionError) as exc:
            errors.append(f"{name}: expr/answer bermasalah ({exc})")
    return errors


def self_test():
    keys = {lang: {"T", "H1", "H2", "H3", "E"} for lang in LANGS}
    good = {"id": "ok", "act": 1, "grade": 3, "topic": "x", "text": "T", "expr": "3*12+8",
            "answer": "44", "hints": ["H1", "H2", "H3"], "explanation": "E"}
    assert not validate_puzzles([good], keys, "uji"), "soal benar seharusnya lolos"
    frac = dict(good, id="frac", expr="1/2+1/4", answer="3/4")
    assert not validate_puzzles([frac], keys, "uji"), "pecahan seharusnya lolos"
    assert validate_puzzles([dict(good, answer="45")], keys, "uji"), "jawaban salah harus terdeteksi"
    assert validate_puzzles([dict(good, hints=["H1"])], keys, "uji"), "petunjuk kurang harus terdeteksi"
    assert validate_puzzles([dict(good, text="NOPE")], keys, "uji"), "kunci hilang harus terdeteksi"
    assert validate_puzzles([dict(good, expr="__import__('os')")], keys, "uji"), "expr berbahaya harus ditolak"
    print("validate_data: self-test lolos")
    return 0


def main():
    if "--self-test" in sys.argv:
        return self_test()
    text_keys = load_texts()
    errors = []
    per_act = {}
    files = sorted(p for p in (ROOT / "content").rglob("puzzles.json"))
    for path in files:
        puzzles = json.loads(path.read_text(encoding="utf-8"))
        errors += validate_puzzles(puzzles, text_keys, path.relative_to(ROOT).as_posix())
        for puzzle in puzzles:
            per_act[puzzle.get("act")] = per_act.get(puzzle.get("act"), 0) + 1
    for act, count in sorted(per_act.items(), key=lambda kv: str(kv[0])):
        if count < 2:
            errors.append(f"Act {act}: hanya {count} puzzle (minimal 2 menurut brief)")
    for message in errors:
        print("ERROR", message)
    print(f"validate_data: {len(files)} file puzzle, {sum(per_act.values())} soal, {len(errors)} error")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
