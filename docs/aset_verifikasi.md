# Hasil verifikasi aset (Fase 1)

Pemeriksaan aset yang masih ragu di rencana. Dilakukan dengan membuka tileset dan mendaftar isi folder asset pack.

| Kebutuhan | Hasil | Keputusan |
|---|---|---|
| Kristal pengatur energi (3 buah) dan kristal ungu kecil | `Items/Resource` punya `GemGreen`, `GemRed`, `GemYellow`, `GemPurple` | **Dipakai.** 3 kristal desa = hijau, merah, kuning; kristal ungu kecil = adegan setelah kredit dan simbol Kuro. Efek cahaya ditambah lewat partikel |
| Bulu ayam (proyektil Kibas Bulu) | `Items/Resource/feather.png` ada | **Dipakai** |
| Bom asap Farah | `Items/Projectile`: `Bomb`, `Caltrop`, `Dynamite`, `CrateDynamite`; efek `FX/Smoke` | **Dipakai** (Bomb di-recolor, asap dari FX) |
| Penyembuh (Dokter Zahra) | `Items/Potion`: `Heart`, `LifePot`, `Medipack`, `MilkPot` | **Dipakai** |
| Boneka latihan | **Tidak ada** | **Dibuat** (A4): boneka jerami/kayu berbasis tile kayu dan karung |
| Sumur desa | Ada objek berbentuk cincin batu di preview `TilesetHouse`/`TilesetElement`; belum dipastikan sebagai sumur | Dipastikan saat menyusun peta (Fase 6). Jika tidak cocok: **dibuat** |
| Jembatan gantung (Act 7) | Tidak terlihat di `TilesetNature` dan `TilesetRelief` (hanya tebing hijau/oranye/es dan pohon, bambu, jamur, batu) | Dicek lagi di `TilesetFloor`/`TilesetElement` saat Act 7; jika tidak ada: **dibuat** dari tile papan kayu dan tali |
| Bambu, jamur, pohon, batu | `TilesetNature` lengkap (bambu hijau, jamur berbagai warna, pohon musim berbeda, batu) | **Dipakai** |
| Rumah ninja, dojo, torii, kios, patung penjaga | `TilesetHouse` lengkap | **Dipakai** |
| Hewan kecil: ayam, kucing, babi hutan | Sheet kecil (32x16 atau 34x16: dua frame 16x16), tanpa 4 arah | Untuk boss: skala 2x-4x + overlay + animasi lari lewat kode (bobbing dan flip) |
| Slime dan jamur | `Slime.png` 64x64 dan `mushroom.png` 64x64 (grid beberapa frame) | **Dipakai**, recolor ungu untuk slime |
| Format karakter | Semua `Actor/Character/*/SpriteSheet.png` 64x112 (4 arah x 7 baris) + `Faceset.png` 38x38 | Format sama dengan `SpriteCharacter` di proyek, jadi 95 karakter bisa dipakai langsung |
| `CharacterAnimated/NinjaGreen` | Satu karakter dengan banyak animasi (roll, climb, push, swim) | Cadangan jika Arka perlu animasi roll/climb; tidak dipakai default |
| Suara ayam | Tidak ada di `Audio/Sounds/Creature` (ada `Bird`, `Dog`, `Duck`, `Wings`) | A13: dibuat dari `Bird`/`Duck` dengan pitch-shift |
| Font | `Ui/Font/NormalFont.ttf` huruf Latin | Cukup untuk ID dan EN |
