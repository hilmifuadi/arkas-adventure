#!/usr/bin/env python3
"""Buat prop kecil buatan skrip (deterministik, Pillow): boneka latihan jerami.

Hasil: assets/generated/props/training_dummy.png (16x24). Palet diambil dari warna pack
(Palette.png) agar menyatu: kayu, jerami, merah sasaran, kontur gelap.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "generated" / "props"

OUTLINE = (20, 27, 27, 255)
WOOD = (150, 83, 64, 255)
WOOD_LIGHT = (163, 117, 78, 255)
STRAW = (241, 196, 113, 255)
STRAW_DARK = (215, 139, 74, 255)
RED = (224, 57, 76, 255)
WHITE = (242, 234, 241, 255)


def ellipse(img, cx, cy, rx, ry, color, shade=None):
    for y in range(img.height):
        for x in range(img.width):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                img.putpixel((x, y), shade if shade and (x - cx) > rx * 0.35 else color)


def outline(img):
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and src.getpixel((nx, ny))[3]:
                    img.putpixel((x, y), OUTLINE)
                    break


def training_dummy():
    img = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    for y in range(9, 22):  # tiang
        for x in (7, 8):
            img.putpixel((x, y), WOOD if x == 7 else WOOD_LIGHT)
    for x in range(2, 14):  # palang lengan
        img.putpixel((x, 12), WOOD)
        img.putpixel((x, 13), WOOD_LIGHT)
    for x in range(4, 12):  # alas
        for y in (21, 22):
            img.putpixel((x, y), WOOD if y == 21 else WOOD_LIGHT)
    ellipse(img, 8, 10, 5.0, 4.5, STRAW, STRAW_DARK)  # badan jerami
    ellipse(img, 8, 3.8, 3.0, 2.8, STRAW, STRAW_DARK)  # kepala karung
    for x in (7, 8):  # ikat leher
        img.putpixel((x, 6), RED)
    for x, y in ((8, 9), (7, 10), (8, 10), (9, 10), (8, 11)):  # tanda sasaran
        img.putpixel((x, y), RED if (x, y) != (8, 10) else WHITE)
    outline(img)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    training_dummy().save(OUT / "training_dummy.png")
    print("dibuat:", (OUT / "training_dummy.png").relative_to(ROOT).as_posix())


if __name__ == "__main__":
    main()
