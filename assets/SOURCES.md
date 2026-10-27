# Sumber aset

Semua aset di folder ini harus tercatat di sini.

## Ninja Adventure Asset Pack (CC0)

- Pembuat: Pixel-boy dan AAA
- Halaman: https://pixel-boy.itch.io/ninja-adventure-asset-pack
- Lisensi: Creative Commons Zero (CC0). Salinan: `LICENSE_NinjaAdventure_CC0.txt`.
- Atribusi tidak wajib, tetapi dicantumkan di kredit game.

Hanya aset yang dipakai yang disalin dari pack ke repo. Pack penuh disimpan di luar repo.

## Aset buatan sendiri

Aset hasil skrip (`tools/gen_*.py`) tersimpan di `assets/generated/` dan dibuat ulang dari
sprite pack, sehingga tetap CC0. Setiap skrip mencatat sprite sumbernya di dalam file.

## Aset dari sample resmi (`content/`, `system/`, `theme/`, `audio/`)

Berasal dari proyek sample Ninja Adventure oleh Pixel-boy (CC0).

## Karakter buatan skrip (`assets/generated/characters/`, dibuat oleh `tools/gen_characters.py`)

Sprite sheet 64x112 dan faceset 38x38 dengan format yang sama dengan `Actor/Character/*` di pack.
Dibuat ulang secara deterministik (recolor palet + aksesori piksel); jangan diedit tangan.

| Tokoh | Sprite sumber di pack | Perubahan |
|---|---|---|
| Arka | `Actor/Character/NinjaGreen` | hijau daun, ikat kepala oranye, katana di punggung |
| Bida | `Actor/Character/NinjaBlue` | biru tua, kacamata bulat, kuncir, gulungan strategi di punggung |
| Nadiya | `Actor/Character/NinjaRed2` | merah, ikat rambut tinggi (sanggul), bandolir shuriken |
| Farah | `Actor/Character/NinjaYellow` | kuning, goggle di dahi, ransel dengan antena |
| Pak Hilmi | `Actor/Character/OldMan2` | topi Hokage berlambang emas, rambut putih |
| Dokter Zahra | `Actor/Character/Woman` | jas putih dengan palang merah |

Pack sumber: `Ninja Adventure - Asset Pack/Actor/Character/` (folder pack ada di luar repo).
Skrip mencari pack otomatis di folder induk repo, atau pakai `--pack "<folder>"`.
Scene tokoh ada di `content/characters/<nama>/<nama>.tscn`.
