# Petualangan Arka di Kampung Ninja

*Arka's Adventure in Ninja Village*

Game petualangan top-down 2D untuk keluarga, dibuat dengan Godot 4 (GDScript).
Arka dan saudara-saudaranya (Bida, Nadiya, Farah), anak Hokage Pak Hilmi dan Dokter Zahra, menyelamatkan **Desa Daun** dari krisis yang
awalnya konyol, lalu perlahan membuka misteri besar. Di sepanjang jalan ada puzzle cerita
matematika untuk kelas 3-5 SD, lengkap dengan kertas coretan.

Game tersedia dalam **Bahasa Indonesia** dan **English** (pilih di layar judul).

> Status: dalam pengembangan. Dibangun bertahap per episode (lihat `docs/`).
> Versi web (GitHub Pages) baru disiapkan ketika sebuah episode siap rilis.

## Menjalankan

1. Pasang [Godot 4.7](https://godotengine.org/download). Proyek hanya memakai GDScript, jadi build standar cukup.
2. Buka `project.godot` di Godot lalu tekan F5.

Proyek memakai renderer **Compatibility** agar tampilan di desktop dan web sama.

## Kontrol

| Aksi | Keyboard | Gamepad |
|---|---|---|
| Bergerak | Panah atau WASD | D-pad / stik kiri |
| Serang | Z atau Spasi | A |
| Dash | X atau Shift | B |
| Interaksi / bicara | E atau Enter | Y |
| Kemampuan Bida (Analisis) | 1 | X |
| Kemampuan Nadiya (Bidik) | 2 | RB |
| Kemampuan Farah (Gadget) | 3 | LB |
| Kertas coretan | Tab | R3 (tekan stik kanan) |
| Tampilkan objektif (tahan) | O | Back |
| Jeda | Esc | Start |

Kertas coretan memakai mouse. Kontrol sentuh untuk HP/tablet ditambahkan menjelang rilis.

## Struktur proyek

```
assets/      aset terpilih dari pack + hasil generate (lihat assets/SOURCES.md)
content/     konten game: menu, karakter, musuh, boss, peta per Act, puzzle
system/      mesin game (karakter, senjata, damage, peta, UI) dan sistem inti (system/core)
translations/ teks game dua bahasa (ui.id.json / ui.en.json)
tools/       linter konsistensi brief, validator data, smoke test, generator aset, uji otomatis
docs/        Story Bible dan desain per Act
```

## Pemeriksaan kualitas

```
python tools/check_all.py                                  # linter brief + validator data + smoke test Godot
godot --headless --path . --script tools/smoke_test.gd     # hanya smoke test (exit 1 bila ada error skrip/resource)
godot --path . --script tools/playtest_e2e.gd -- <folder>  # uji ujung ke ujung + screenshot (butuh jendela)
```

Uji gameplay lain: `tools/playtest_player.gd`, `playtest_interact.gd`, `playtest_dialog.gd`, `playtest_audio.gd`,
`playtest_world.gd`, `playtest_hud.gd`. Aset buatan skrip dibuat ulang dengan `python tools/gen_characters.py` dan `python tools/gen_props.py`;
peta uji dengan `godot --headless --path . --script tools/build_maps.gd`. Catatan Fase 2 ada di `docs/fase2_catatan.md`.

## Kredit

Proyek ini berawal dari [sample Ninja Adventure](https://github.com/pixel-boy/NinjaAdventure)
dan memakai [Ninja Adventure Asset Pack](https://pixel-boy.itch.io/ninja-adventure-asset-pack)
oleh **Pixel-boy** dan **AAA** (lisensi CC0). Lihat `assets/SOURCES.md`.
