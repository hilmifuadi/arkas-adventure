#!/usr/bin/env python3
"""Buat sprite sheet dan faceset tokoh Fase 2 (Bida, Nadiya, Farah, Dokter Zahra berhijab/tudung ninja) dari sprite "Ninja Adventure - Asset Pack".

Deterministik (tanpa angka acak). Hanya butuh Python 3 + Pillow. Hasil:
  assets/generated/characters/<nama>/SpriteSheet.png   64x112 (4 arah x 7 baris, format sama dengan pack)
  assets/generated/characters/<nama>/Faceset.png      38x38

Cara kerja: tiap tokoh = sprite pack sebagai basis + (1) recolor palet per bagian (kepala/badan)
+ (2) aksesori piksel kecil yang ditempel relatif terhadap kepala tiap frame (ikat kepala,
kacamata, goggle, ransel, topi, jas) sehingga mengikuti arah dan animasi jalan.

Pemakaian:
  python tools/gen_characters.py [--pack "<folder Actor/Character di asset pack>"]
  Bila --pack tidak diberikan, dicari di ../../Ninja Adventure - Asset Pack relatif ke repo.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "generated" / "characters"

OUTLINE = (20, 27, 27, 255)
CELL = 16
DOWN, UP, LEFT, RIGHT = 0, 1, 2, 3


def rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def find_pack():
    for base in (ROOT.parent.parent, ROOT.parent, ROOT):
        for candidate in base.glob("Ninja Adventure - Asset Pack/**/Actor/Character"):
            return candidate
    sys.exit("Asset pack tidak ditemukan; pakai --pack")


# ---------------------------------------------------------------- bantuan piksel

def is_opaque(img, x, y):
    return 0 <= x < img.width and 0 <= y < img.height and img.getpixel((x, y))[3] > 0


def head_anchor(cell):
    """(top, cx): baris teratas kepala (>=6 piksel) dan titik tengah kepala pada baris top+6."""
    top = None
    for y in range(CELL):
        if sum(is_opaque(cell, x, y) for x in range(CELL)) >= 6:
            top = y
            break
    if top is None:
        return None
    probe = min(top + 6, CELL - 1)
    xs = [x for x in range(CELL) if is_opaque(cell, x, probe)] or [7, 8]
    return top, (min(xs) + max(xs)) // 2


def recolor(cell, mapping, top, body_mapping=None, tuft_mapping=None):
    """Recolor satu frame. mapping untuk semua piksel; body_mapping menimpa untuk badan
    (baris >= top+9); tuft_mapping menimpa piksel di atas kepala (baris < top)."""
    out = cell.copy()
    for y in range(CELL):
        for x in range(CELL):
            color = cell.getpixel((x, y))
            if color[3] == 0 or color == OUTLINE:
                continue
            table = mapping
            if top is not None:
                if body_mapping and y >= top + 9:
                    table = {**mapping, **body_mapping}
                if tuft_mapping and y < top:
                    table = {**mapping, **tuft_mapping}
            if color in table:
                out.putpixel((x, y), table[color])
    return out


def put(cell, x, y, color, over=True):
    """Tempel satu piksel. over=False hanya mengisi piksel yang masih transparan (di belakang tubuh)."""
    if not (0 <= x < CELL and 0 <= y < CELL):
        return
    if not over and cell.getpixel((x, y))[3] > 0:
        return
    cell.putpixel((x, y), color)


def paint_row(cell, y, x0, x1, color, skip_outline=True):
    """Warnai piksel buram pada satu baris (dipakai untuk ikat kepala yang melingkar)."""
    for x in range(x0, x1 + 1):
        if is_opaque(cell, x, y) and not (skip_outline and cell.getpixel((x, y)) == OUTLINE):
            cell.putpixel((x, y), color)


def opaque_span(cell, y):
    xs = [x for x in range(CELL) if is_opaque(cell, x, y)]
    return (min(xs), max(xs)) if xs else None


def side_sign(direction):
    """+1 jika punggung ada di kanan layar (menghadap kiri), -1 jika di kiri (menghadap kanan)."""
    return 1 if direction == LEFT else -1


# ---------------------------------------------------------------- fitur per tokoh

def neck_cloth(cell, top, cx, color, trim, wide=5, widths=None):
    """Kain tudung/hijab yang menutup leher dan jatuh membentuk segitiga kecil di dada.
    Dua baris pertama melebar, baris ketiga menyempit; garis tepi (trim) memberi kesan lipatan.
    widths: daftar setengah-lebar per baris (mulai top+9) untuk hijab panjang."""
    if widths:
        rows = [(top + 9 + i, half, trim if i == 0 else color) for i, half in enumerate(widths)]
    else:
        rows = ((top + 9, wide, trim), (top + 10, wide - 1, color), (top + 11, max(wide - 3, 1), color))
    for y, half, edge in rows:
        for x in range(cx - half + 1, cx + half + 1):
            if is_opaque(cell, x, y) and cell.getpixel((x, y)) != OUTLINE:
                cell.putpixel((x, y), edge if x in (cx - half + 1, cx + half) else color)


def cloth_tail(cell, d, top, cx, color, shade):
    """Ujung kain tudung yang berkibar di belakang kepala (terlihat dari belakang dan samping)."""
    s = side_sign(d)
    if d == UP:
        for i in range(4):
            put(cell, cx + 1 + (i // 2), top + 6 + i, color if i % 2 == 0 else shade, over=True)
        put(cell, cx + 1, top + 10, shade)
    elif d in (LEFT, RIGHT):
        put(cell, cx + 6 * s, top + 5, color)
        put(cell, cx + 7 * s, top + 6, shade)
        put(cell, cx + 7 * s, top + 7, color)
    else:
        put(cell, cx + 6, top + 8, shade)



def arka_features(cell, d, top, cx, row):
    band, band_hi = rgb("f08a1e"), rgb("ffc247")
    span = opaque_span(cell, top + 5)
    if span:
        paint_row(cell, top + 5, span[0], span[1], band)
        # kilau tipis pada ikat kepala
        if d in (DOWN, LEFT, RIGHT):
            put(cell, cx - 2, top + 5, band_hi)
    # katana di punggung: gagang di atas bahu dan sarung diagonal di badan
    steel, wrap, sheath = rgb("e8edf2"), rgb("7a3b22"), rgb("4a2a1c")
    s = side_sign(d)
    if d == UP:
        for i in range(6):
            put(cell, cx + 3 - i, top + 9 + i * 5 // 6 + (1 if i > 2 else 0), sheath)
        put(cell, cx + 4, top + 8, wrap)
        put(cell, cx + 5, top + 7, steel, over=False)
    elif d == DOWN:
        put(cell, cx + 5, top + 9, wrap, over=False)
        put(cell, cx + 6, top + 8, steel, over=False)
    else:
        put(cell, cx + 5 * s, top + 8, wrap)
        put(cell, cx + 6 * s, top + 7, steel, over=False)
        put(cell, cx + 4 * s, top + 10, sheath)
        put(cell, cx + 3 * s, top + 11, sheath)


def bida_features(cell, d, top, cx, row):
    rim, glint = rgb("d6ecff"), rgb("ffffff")
    s = side_sign(d)
    eye_y = top + 7
    if d == DOWN:
        for x0 in (cx - 4, cx + 2):
            for dx in range(3):
                put(cell, x0 + dx, eye_y - 1, rim)
                put(cell, x0 + dx, eye_y + 2, rim)
            put(cell, x0, eye_y, rim)
            put(cell, x0, eye_y + 1, rim)
            put(cell, x0 + 2, eye_y, rim)
            put(cell, x0 + 2, eye_y + 1, rim)
            put(cell, x0 + 1, eye_y, glint)
        put(cell, cx - 1, eye_y, rim)
        put(cell, cx, eye_y, rim)
    elif d in (LEFT, RIGHT):
        fx = cx - 4 * s
        for dx in range(3):
            put(cell, fx + dx * -s, eye_y - 1, rim)
            put(cell, fx + dx * -s, eye_y + 2, rim)
        put(cell, fx, eye_y, rim)
        put(cell, fx, eye_y + 1, rim)
        put(cell, fx - 2 * s, eye_y, rim)
        put(cell, fx - 2 * s, eye_y + 1, rim)
        put(cell, fx - s, eye_y, glint)
    # tudung ninja biru tua: kain menutup leher, ujungnya berkibar, garis tepi biru muda
    cloth, trim, shade = rgb("2f4ea0"), rgb("4a6cc0"), rgb("23366e")
    neck_cloth(cell, top, cx, cloth, trim)
    cloth_tail(cell, d, top, cx, cloth, shade)
    # gulungan strategi di punggung
    paper, rod = rgb("f1e4c0"), rgb("8a5a2b")
    if d == UP:
        for i in range(5):
            put(cell, cx - 3 + i, top + 12 + i // 3, paper)
        put(cell, cx - 4, top + 12, rod)
        put(cell, cx + 2, top + 13, rod)
    elif d in (LEFT, RIGHT):
        put(cell, cx + 4 * s, top + 11, paper)
        put(cell, cx + 4 * s, top + 12, rod)


def nadiya_features(cell, d, top, cx, row):
    # tudung ninja merah: ujung kain berkibar (tuft bawaan sprite), pita kuning di sisi tudung
    cloth, trim, shade, pin = rgb("e8364c"), rgb("f0566a"), rgb("a62e48"), rgb("ffd23c")
    neck_cloth(cell, top, cx, cloth, trim)
    cloth_tail(cell, d, top, cx, cloth, shade)
    if d == DOWN:
        put(cell, cx - 6, top + 4, pin)
        put(cell, cx - 6, top + 5, pin)
    elif d == UP:
        put(cell, cx - 3, top + 3, pin)
        put(cell, cx - 2, top + 3, pin)
    else:
        s = side_sign(d)
        put(cell, cx + 2 * s, top + 3, pin)
        put(cell, cx + 3 * s, top + 3, pin)
    # bandolir: tali menyilang di dada dengan shuriken kecil
    strap, metal = rgb("4a2c1a"), rgb("ffd23c")
    if d == DOWN:
        for i in range(6):
            put(cell, cx - 3 + i, top + 10 + i * 4 // 6, strap)
        put(cell, cx - 1, top + 11, metal)
        put(cell, cx + 1, top + 12, metal)
    elif d == UP:
        for i in range(6):
            put(cell, cx + 2 - i, top + 10 + i * 4 // 6, strap)
    else:
        s = side_sign(d)
        put(cell, cx - 1 * s, top + 10, strap)
        put(cell, cx, top + 11, strap)
        put(cell, cx + 1 * s, top + 12, strap)
        put(cell, cx, top + 11, metal)


def farah_features(cell, d, top, cx, row):
    rim, glass, glint, strap = rgb("2d3b52"), rgb("62d6ee"), rgb("ffffff"), rgb("3a2a22")
    s = side_sign(d)
    # tudung ninja kuning: menutup leher, ujung kain berkibar
    cloth, trim, shade = rgb("ffd84a"), rgb("fff1a0"), rgb("f2a62a")
    neck_cloth(cell, top, cx, cloth, trim)
    cloth_tail(cell, d, top, cx, cloth, shade)
    # goggle di dahi (di atas tudung) + tali
    span = opaque_span(cell, top + 3)
    if span and d != UP:
        paint_row(cell, top + 4, span[0], span[1], strap)
    if d == DOWN:
        for x0 in (cx - 5, cx + 2):
            for dx in range(4):
                put(cell, x0 + dx, top + 2, rim)
                put(cell, x0 + dx, top + 5, rim)
            put(cell, x0, top + 3, rim)
            put(cell, x0 + 3, top + 3, rim)
            put(cell, x0, top + 4, rim)
            put(cell, x0 + 3, top + 4, rim)
            put(cell, x0 + 1, top + 3, glint)
            put(cell, x0 + 2, top + 3, glass)
            put(cell, x0 + 1, top + 4, glass)
            put(cell, x0 + 2, top + 4, glass)
    elif d in (LEFT, RIGHT):
        fx = cx - 3 * s
        for dx in range(4):
            put(cell, fx - dx * s, top + 2, rim)
            put(cell, fx - dx * s, top + 5, rim)
        put(cell, fx, top + 3, rim)
        put(cell, fx, top + 4, rim)
        put(cell, fx - 3 * s, top + 3, rim)
        put(cell, fx - 3 * s, top + 4, rim)
        put(cell, fx - s, top + 3, glint)
        put(cell, fx - 2 * s, top + 3, glass)
        put(cell, fx - s, top + 4, glass)
        put(cell, fx - 2 * s, top + 4, glass)
    else:
        for dx in range(-5, 6):
            put(cell, cx + dx, top + 4, strap)
    # ransel + antena (antena terlihat dari semua arah)
    pack, pack_hi, tip = rgb("6b6f7a"), rgb("9aa0ad"), rgb("ff4a4a")
    put(cell, cx + 4, top - 1, rim)
    put(cell, cx + 4, top - 2, tip)
    put(cell, cx - 3, top - 1, rim)
    put(cell, cx - 3, top - 2, tip)
    if d == UP:
        for yy in range(top + 8, top + 13):
            for xx in range(cx - 4, cx + 4):
                put(cell, xx, yy, pack_hi if (xx + yy) % 5 == 0 else pack)
        put(cell, cx - 4, top + 8, OUTLINE)
        put(cell, cx + 3, top + 8, OUTLINE)
    elif d == DOWN:
        for yy in range(top + 10, top + 14):
            put(cell, cx - 6, yy, pack)
            put(cell, cx + 6, yy, pack)
    else:
        for yy in range(top + 9, top + 13):
            for xx in range(2):
                put(cell, cx + (4 + xx) * s, yy, pack_hi if xx else pack)


def hilmi_features(cell, d, top, cx, row):
    gold, white = rgb("f5c542"), rgb("f4ecf0")
    # lambang di topi Hokage
    if d == DOWN:
        put(cell, cx, top + 3, gold)
        put(cell, cx + 1, top + 3, gold)
        put(cell, cx, top + 4, gold)
    # tepi putih topi
    span = opaque_span(cell, top + 5)
    if span and d != DOWN:
        paint_row(cell, top + 5, span[0], span[1], white)
    elif span:
        paint_row(cell, top + 5, span[0], span[1], white)


def zahra_features(cell, d, top, cx, row):
    red = rgb("e0394c")
    # hijab biru muda yang lembut dan panjang: menutup kepala, leher, bahu, dan dada; ujungnya berkibar
    cloth, trim, shade = rgb("b0d0e8"), rgb("cfe3f3"), rgb("86aed0")
    neck_cloth(cell, top, cx, cloth, trim, widths=[7, 7, 6, 4, 2])
    # lipatan kecil: garis bayangan menurun dari leher
    for i in range(3):
        for sign in (-1, 1):
            xx = cx + sign * (2 + i) - (1 if sign < 0 else 0)
            if is_opaque(cell, xx, top + 10 + i) and cell.getpixel((xx, top + 10 + i)) == cloth:
                cell.putpixel((xx, top + 10 + i), shade)
    cloth_tail(cell, d, top, cx, cloth, shade)
    if d == DOWN:
        # palang kesehatan sebagai lencana di dada kanan (di atas kain)
        put(cell, cx + 3, top + 11, red)
        put(cell, cx + 2, top + 12, red)
        put(cell, cx + 3, top + 12, red)
        put(cell, cx + 4, top + 12, red)
        put(cell, cx + 3, top + 13, red)
    elif d in (LEFT, RIGHT):
        put(cell, cx, top + 12, red)
        put(cell, cx, top + 13, red)


# ---------------------------------------------------------------- definisi tokoh

CHARACTERS = {
    "arka": {
        "base": "NinjaGreen",
        "map": {
            rgb("a8a129"): rgb("62b246"),   # tudung terang -> hijau daun
            rgb("56864c"): rgb("3e8a44"),
            rgb("345a52"): rgb("24603e"),
        },
        "body": {},
        "tuft": {rgb("56864c"): rgb("f08a1e"), rgb("a8a129"): rgb("ffa02e")},
        "features": arka_features,
    },
    "bida": {
        "base": "NinjaBlue",
        "map": {
            rgb("79b8ce"): rgb("2f4ea0"),   # biru langit -> biru tua
            rgb("f2eaf1"): rgb("7f9be0"),   # putih -> biru muda (kilau)
            rgb("5f7160"): rgb("23366e"),
            rgb("f1c471"): rgb("f1c471"),
        },
        "body": {},
        "tuft": {},
        "features": bida_features,
    },
    "nadiya": {
        "base": "NinjaRed2",
        "map": {
            rgb("e0394c"): rgb("e8364c"),
            rgb("8f3e56"): rgb("a62e48"),
            rgb("543c52"): rgb("5d2a40"),
        },
        "body": {},
        "tuft": {rgb("8f3e56"): rgb("c43a56"), rgb("e0394c"): rgb("f0566a")},
        "features": nadiya_features,
    },
    "farah": {
        "base": "NinjaYellow",
        "map": {
            rgb("f1c471"): rgb("ffd84a"),   # kuning lebih cerah
            rgb("d78b4a"): rgb("f2a62a"),
            rgb("e0394c"): rgb("f2a62a"),   # bunga merah -> oranye (diganti goggle)
        },
        "body": {rgb("d14b34"): rgb("2fa59a"), rgb("96533f"): rgb("1f6b66"), rgb("a3754e"): rgb("2a8a82")},
        "tuft": {},
        "features": farah_features,
    },
    "pak_hilmi": {
        "base": "OldMan2",
        "map": {
            rgb("d3a2c0"): rgb("e8e0e6"),   # rambut ungu-abu -> putih
            rgb("e0394c"): rgb("d6283c"),
            rgb("8f3e56"): rgb("a02a44"),
        },
        "body": {},
        "tuft": {},
        "features": hilmi_features,
    },
    "dokter_zahra": {
        "base": "Woman",
        "map": {
            rgb("79b8ce"): rgb("f1f4f8"),   # baju biru -> jas putih
            rgb("548789"): rgb("c4ccd8"),
            rgb("f1c471"): rgb("b0d0e8"),   # rambut pirang terang -> hijab biru muda
            rgb("d78b4a"): rgb("86aed0"),   # rambut pirang gelap -> bayangan hijab
            rgb("cf736d"): rgb("ef914f"),   # semburat pipi/telinga di kepala -> warna kulit (telinga tertutup)
        },
        # badan: leher/kerah merah muda menjadi kain hijab, tangan tertutup lengan jas putih
        "body": {rgb("cf736d"): rgb("b0d0e8"), rgb("ef914f"): rgb("f1f4f8")},
        "tuft": {},
        "features": zahra_features,
    },
}

# Faceset: recolor global + coretan piksel. Koordinat dalam gambar 38x38.
FACE_MAPS = {
    "arka": {
        rgb("a8a129"): rgb("62b246"), rgb("56864c"): rgb("3e8a44"), rgb("345a52"): rgb("24603e"),
    },
    "bida": {
        rgb("79b8ce"): rgb("2f4ea0"), rgb("f2eaf1"): rgb("7f9be0"), rgb("5f7160"): rgb("23366e"),
    },
    "nadiya": {
        rgb("e0394c"): rgb("e8364c"), rgb("8f3e56"): rgb("a62e48"), rgb("543c52"): rgb("5d2a40"),
    },
    "farah": {
        rgb("f1c471"): rgb("ffd84a"), rgb("d78b4a"): rgb("f2a62a"), rgb("e0394c"): rgb("f2a62a"),
    },
    "pak_hilmi": {rgb("d3a2c0"): rgb("e8e0e6")},
    "dokter_zahra": {
        rgb("79b8ce"): rgb("f1f4f8"), rgb("548789"): rgb("c4ccd8"),
        rgb("f1c471"): rgb("b0d0e8"), rgb("d78b4a"): rgb("86aed0"),
    },
}


def fill(img, x0, y0, x1, y1, color):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                img.putpixel((x, y), color)


def ring(img, cx, cy, r, color):
    """Lingkaran piksel (lensa kacamata/goggle)."""
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if r * r - r <= d2 <= r * r + r:
                put_img(img, x, y, color)


def put_img(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def face_neck_cloth(img, color, trim, shade):
    """Kain tudung menutup leher di faceset: pita kain (tepi terang + 3 baris kain + lipatan)."""
    for x in range(4, 35):
        for y, tone in ((29, trim), (30, color), (31, color), (32, shade)):
            px = img.getpixel((x, y))
            if px != OUTLINE:
                img.putpixel((x, y), tone)
    for x in range(10, 29, 4):  # lipatan kecil
        if img.getpixel((x, 31)) != OUTLINE:
            img.putpixel((x, 31), shade)


def zahra_hijab_face(img):
    """Dokter Zahra: hijab sangat tertutup ala hijab muslimah. Seluruh rambut, dahi atas, sisi wajah,
    telinga, dan leher tertutup kain; kain jatuh menutup bahu dan dada. Hanya wajah (mata, hidung, mulut)
    yang terlihat, dibingkai garis tepi kain gelap + tepi terang. Piksel wajah diambil dari sprite pack."""
    orig = img.copy()
    cloth, shade, light, trim = rgb("b0d0e8"), rgb("86aed0"), rgb("f1f4f8"), rgb("cfe3f3")
    coat, red = rgb("c4ccd8"), rgb("e0394c")
    cx, cy, rx, ry = 17.3, 21.2, 8.0, 5.8  # lubang wajah

    def silhouette(x, y):
        dome = ((x - 17.5) / 11.8) ** 2 + ((y - 15.5) / 12.8) ** 2 <= 1.0
        drape = y >= 25 and abs(x - 17.5) <= 9.5 + 9.5 * (((y - 25) / 12.0) ** 0.6)
        return dome or drape

    for y in range(img.height):
        for x in range(img.width):
            img.putpixel((x, y), OUTLINE)
    for y in range(img.height):
        for x in range(img.width):
            if not silhouette(x, y):
                continue
            tone = cloth
            lean = (x - 17.5) * 0.9 + (y - 15.5) * 0.3
            if lean > 8.0:
                tone = shade  # sisi kanan lebih gelap
            elif (x - 17.5) * 0.9 + (y - 15.5) * 0.6 < -9.0:
                tone = light  # kilau kiri atas
            if y >= 28:  # lipatan berbentuk V dari leher, dan lipatan tengah
                fold = abs(abs(x - 17.5) - ((y - 27) * 0.9 + 3.0))
                if fold < 0.65:
                    tone = shade
                elif y >= 31 and abs(x - 17.5) < 0.6:
                    tone = trim
            img.putpixel((x, y), tone)
    for y in range(img.height):
        for x in range(img.width):
            e = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if e <= 1.0:
                pixel = orig.getpixel((x, y))
                if pixel == rgb("cf736d") and (x > 22 or x < 12):
                    pixel = rgb("ef914f")  # semburat telinga di tepi wajah diganti warna kulit (telinga tertutup)
                img.putpixel((x, y), pixel)
            elif e <= 1.2:
                img.putpixel((x, y), OUTLINE)  # garis tepi kain di sekeliling wajah
            elif e <= 1.5 and silhouette(x, y):
                img.putpixel((x, y), trim)  # tepi kain terang
    # jas putih di sudut bawah dan palang merah sebagai lencana di dada kanan
    for y in range(33, 38):
        for x in list(range(0, 3)) + list(range(35, 38)):
            img.putpixel((x, y), coat)
    for pt in ((28, 31), (27, 32), (28, 32), (29, 32), (28, 33)):
        img.putpixel(pt, red)


def face_overlay(name, img):
    band, hi = rgb("f08a1e"), rgb("ffc247")
    if name == "arka":
        # ikat kepala oranye melintang di dahi + ekor di kanan atas
        for y in (10, 11, 12):
            for x in range(4, 33):
                px = img.getpixel((x, y))
                if px[3] and px != OUTLINE:
                    img.putpixel((x, y), band if y != 10 else hi)
        for pt in ((31, 4), (32, 4), (33, 3), (32, 5), (33, 5), (34, 6)):
            put_img(img, *pt, band)
        # alis tebal dan senyum percaya diri
        fill(img, 9, 13, 14, 13, OUTLINE)
        fill(img, 21, 13, 26, 13, OUTLINE)
    elif name == "bida":
        # kacamata bulat di atas visor
        ring(img, 13, 17, 5, rgb("d6ecff"))
        ring(img, 24, 17, 5, rgb("d6ecff"))
        fill(img, 18, 16, 19, 16, rgb("d6ecff"))
        fill(img, 11, 16, 12, 18, rgb("ffffff"))
        fill(img, 22, 16, 23, 18, rgb("ffffff"))
        # tudung ninja biru tua: garis tepi kain di atas dan kain menutup leher
        fill(img, 8, 8, 30, 8, rgb("4a6cc0"))
        fill(img, 9, 29, 29, 29, rgb("4a6cc0"))
    elif name == "nadiya":
        # tudung ninja merah: garis tepi kain dan pita kuning di sisi tudung
        fill(img, 8, 9, 30, 9, rgb("f0566a"))
        fill(img, 7, 12, 8, 17, rgb("ffd23c"))
        fill(img, 8, 13, 8, 16, rgb("e6a817"))
        # bandolir di dada
        for i in range(24):
            put_img(img, 6 + i, 29 + i // 3, rgb("4a2c1a"))
            put_img(img, 6 + i, 30 + i // 3, rgb("4a2c1a"))
        for pt in ((12, 32), (19, 35), (25, 37)):
            fill(img, pt[0], pt[1], pt[0] + 1, pt[1] + 1, rgb("ffd23c"))
    elif name == "farah":
        # tudung ninja kuning: tepi kain di dahi, kain menutup leher; goggle dipakai di atas tudung
        fill(img, 6, 12, 32, 12, rgb("fff1a0"))
        fill(img, 8, 30, 30, 30, rgb("fff1a0"))
        fill(img, 5, 6, 33, 7, rgb("3a2a22"))
        ring(img, 12, 8, 5, rgb("2d3b52"))
        ring(img, 25, 8, 5, rgb("2d3b52"))
        fill(img, 10, 6, 14, 10, rgb("62d6ee"))
        fill(img, 23, 6, 27, 10, rgb("62d6ee"))
        fill(img, 10, 6, 11, 7, rgb("ffffff"))
        fill(img, 23, 6, 24, 7, rgb("ffffff"))
        # antena
        fill(img, 30, 0, 30, 3, rgb("2d3b52"))
        fill(img, 29, 0, 31, 0, rgb("ff4a4a"))
    elif name == "pak_hilmi":
        # lambang emas di topi Hokage
        fill(img, 17, 5, 20, 8, rgb("f5c542"))
        fill(img, 18, 6, 19, 7, rgb("d6283c"))
    elif name == "dokter_zahra":
        zahra_hijab_face(img)
    if name == "bida":
        face_neck_cloth(img, rgb("2f4ea0"), rgb("4a6cc0"), rgb("23366e"))
    elif name == "nadiya":
        face_neck_cloth(img, rgb("e8364c"), rgb("f0566a"), rgb("a62e48"))
    elif name == "farah":
        face_neck_cloth(img, rgb("ffd84a"), rgb("fff1a0"), rgb("f2a62a"))


# ---------------------------------------------------------------- penyusunan

def build_sheet(name, spec, pack):
    src = Image.open(pack / spec["base"] / "SpriteSheet.png").convert("RGBA")
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    for row in range(src.height // CELL):
        for d in range(src.width // CELL):
            box = (d * CELL, row * CELL, (d + 1) * CELL, (row + 1) * CELL)
            cell = src.crop(box)
            anchor = head_anchor(cell) if row <= 4 else None
            top = anchor[0] if anchor else None
            cell = recolor(cell, spec["map"], top, spec["body"], spec["tuft"] if row <= 4 else None)
            if anchor and row <= 4:
                spec["features"](cell, d, anchor[0], anchor[1], row)
            out.alpha_composite(cell, (box[0], box[1]))
    return out


def build_face(name, spec, pack):
    face = Image.open(pack / spec["base"] / "Faceset.png").convert("RGBA")
    mapping = FACE_MAPS[name]
    for y in range(face.height):
        for x in range(face.width):
            px = face.getpixel((x, y))
            if px[3] and px in mapping:
                face.putpixel((x, y), mapping[px])
    face_overlay(name, face)
    return face


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pack", help="folder Actor/Character di asset pack")
    parser.add_argument("--preview", help="simpan lembar pratinjau PNG di path ini")
    args = parser.parse_args()
    pack = Path(args.pack) if args.pack else find_pack()
    previews = []
    for name, spec in CHARACTERS.items():
        folder = OUT / name
        folder.mkdir(parents=True, exist_ok=True)
        sheet = build_sheet(name, spec, pack)
        face = build_face(name, spec, pack)
        sheet.save(folder / "SpriteSheet.png")
        face.save(folder / "Faceset.png")
        previews.append((name, sheet, face))
        print("dibuat:", folder.relative_to(ROOT).as_posix())
    if args.preview:
        scale = 4
        width = len(previews) * (64 * scale + 8)
        sheet_img = Image.new("RGBA", (width, 112 * scale + 38 * scale + 12), (70, 100, 70, 255))
        for i, (name, sheet, face) in enumerate(previews):
            sheet_img.alpha_composite(sheet.resize((64 * scale, 112 * scale), Image.NEAREST), (i * (64 * scale + 8), 0))
            sheet_img.alpha_composite(face.resize((38 * scale, 38 * scale), Image.NEAREST), (i * (64 * scale + 8), 112 * scale + 12))
        sheet_img.save(args.preview)
        print("pratinjau:", args.preview)


if __name__ == "__main__":
    main()
