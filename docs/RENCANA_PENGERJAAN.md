# Rencana Pengerjaan — Petualangan Arka di Kampung Ninja

> **Status:** DRAFT v2 untuk direview. Belum ada yang dibangun.
> **Tanggal:** 2026-10-27 (v3, 11:19: Fase 0 dan 1 dikerjakan, lihat bagian 11. v2: sudah memuat jawaban Anda: dua bahasa ID/EN, sentuh saat rilis, rilis bertahap per episode, judul baru)
> **Sumber:** `brief_kampung_ninja_desa_daun.md`, folder "Ninja Adventure - Asset Pack", dan proyek Godot di `Godot Project V4\NinjaAdventure`.
> **Mesin:** Godot 4.7.2 (build Mono yang ada di folder, tetapi proyek murni **GDScript**).
> **Deploy web (GitHub Pages):** hanya Fase 9, dan baru ketika sebuah episode benar-benar siap rilis (rilis bertahap, lihat bagian 5.1).

---

## 0. Ringkasan singkat

1. Brief sudah kuat di cerita (10 Act, 4 protagonis, antagonis, tema). Yang belum ada: desain sistem game. Rencana ini menutup celah itu.
2. Asset pack (2.234 file, CC0) sangat cocok: ada 95 karakter dengan format sprite yang sama, 20 boss, 70+ monster, tileset desa/hutan/gunung/dungeon, 40 musik, sekitar 130 SFX, UI dialog, item, FX shuriken/kunai/asap. Sebagian besar kebutuhan visual sudah tersedia.
3. Proyek Godot yang ada adalah **sample resmi Pixel-boy** (gerak, pedang, hitbox, teleporter, kamera per-ruang, transisi, lingkungan/cuaca). Ini fondasi bagus, tetapi **belum ada**: dialog, quest, inventori, save, party/partner, puzzle, boss, UI menu. Semua itu harus dibangun.
4. Yang **tidak ada di pack** dan perlu dibuat: empat protagonis yang berbeda satu sama lain, Pak Hilmi, Dokter Zahra, Kuro, beberapa monster khas cerita (Ayam Ninja, Babi Bertopeng, Kucing Petir raksasa, Hokage Abadi, Bayangan Arka), prop cerita (bubur ungu, simbol mata spiral, sandal, bola benang), dan UI kertas coretan matematika. Saya usulkan dibuat dengan **skrip recolor/overlay pixel** (Python + PIL) agar gayanya tetap sama dengan pack, bukan gambar AI.
5. Strategi: **vertical slice dulu**. Bangun engine + Act 1 yang utuh dan bisa dimainkan, minta persetujuan Anda, baru produksi Act 2–10 dengan pola yang sama (sesuai urutan prioritas di brief bagian 10).
6. Fitur yang tidak disebut jelas di brief tetapi wajib: **puzzle cerita matematika kelas 3–5 SD (minimal 2 per Act, total 20+) dengan kertas coretan**. Ini cukup besar sehingga punya fase sendiri.

7. **Keputusan Anda yang sudah masuk rencana (v2):**
   - Judul: **"Petualangan Arka di Kampung Ninja"** (judul brief lama diganti).
   - Teks game **dua bahasa: Indonesia dan Inggris** dengan pilihan bahasa di pengaturan. Tema edukasi tetap **matematika**.
   - Pengembangan: keyboard + gamepad + mouse. **Virtual joystick/tombol dan layar sentuh baru diadaptasi menjelang rilis.** Kertas coretan dibuat berbasis pointer (mouse) sehingga nanti langsung bisa dipakai jari.
   - Aset karakter dibuat dengan skrip piksel; Remote Control di PC Anda disetujui.
   - **Rilis bertahap per episode** (bagian 5.1).

Sisa pertanyaan kecil ada di bagian 9.

---

## 1. Temuan awal

### 1.1 Proyek Godot yang sudah ada
- Lokasi: `Godot Project V4\NinjaAdventure` (repo git, origin `hilmifuadi/kampung-ninja-inggris`, upstream `pixel-boy/NinjaAdventure`).
- Sudah ada: `Character` (gerak 4 arah, `SpriteCharacter` untuk sheet 16x16), `Weapon`+`Hitbox`+`DamageArea`+tim damage, `Destroyable` (peti, pot, rumput), `Teleporter` + `Transition`, `Map`, `CameraGrid` (kamera per ruang), `EnvironmentArea` (hujan, salju, awan, daun, kabut, sinar, musik, color grading), `Animal`, `Behavior` (follow, follow path, area target finder), `PlayerUi` (hati), tema UI kayu, 1 peta `map_village`, 4 musik.
- Masalah yang harus dibereskan di awal:
  - Renderer masih **Forward Plus**. Untuk web harus **Compatibility**. Lebih aman pindah dari awal supaya tampilan di desktop dan web sama.
  - `config/features` masih "4.3"; perlu dinaikkan ke 4.7.
  - Ada file sampah `*.tmp` (`tes4A3E.tmp`, `wor*.tmp`, `map*.tmp`, `pla6C6F.tmp`); sudah di-`.gitignore`, tinggal dibersihkan.
  - Input map baru punya 4 arah gerak. Belum ada serang, dash, interaksi, kemampuan partner, jeda.
  - `main.gd` memuat langsung `world.tscn`; perlu alur Title → Game → Jeda → Save.
  - README masih bahasa Inggris dan menyebut proyek ini "based on" sample; perlu penyesuaian saat rilis.
- Repo hanya berisi aset yang sudah disalin. Asset pack ada **di luar repo** (hanya referensi lokal).

### 1.2 Asset pack
Kategori, jumlah, dan format yang relevan:

| Kategori | Isi | Catatan |
|---|---|---|
| `Actor/Character` | 95 karakter (ninja berbagai warna, villager, old man/woman, monk, samurai, robot, patung, putri, noble, dll.) | Semua memakai format sama: `SpriteSheet.png` 64x112 (4 arah x 7 baris: idle, jalan, serang, lompat, mati, item) + `Faceset.png` + `SeparateAnim/` |
| `Actor/CharacterAnimated/NinjaGreen` | 1 ninja dengan animasi lebih kaya (roll, climb, swim, push, pickup, hit) + 5 senjata | Hanya 1 karakter; berguna jika kita butuh roll/climb/push untuk Arka |
| `Actor/Boss` | 20 boss (GiantSlime x2, GiantBamboo x2, GiantBlue/RedSamurai, GiantRacoon x2, GiantSpirit, GiantFlam, GiantFrog x2, Dragon, Squid, Tengu, DemonCyclop) | Punya Idle, Walk, Attack, Charge, Hit, Faceset |
| `Actor/Monster` | 70+ (slime x4, jamur x2, bambu x2, kappa, lentera, tikus, burung hantu, bat, ular, spider, dll.) | Format sprite 4 arah |
| `Actor/Animal` | 26 (ayam, babi hutan, kucing x5, anjing, sapi, kuda, monyet, katak, hamster, dll.) | Sheet sangat kecil (ayam 32x16) |
| `Backgrounds/Tilesets` | Field, Floor, FloorB, FloorDetail, House, Element, Nature, Water, Relief, ReliefDetail, Dungeon, Towers, Hole, Pipes, Logic, Desert, VillageAbandoned, Interior (+Elements, WallSimple) | Ada rumah ninja, dojo, torii, patung penjaga, pagar, kios pasar |
| `Backgrounds/Animated` | Bendera 8 warna, bunga, tanaman, riak air, air terjun, kincir, pasir hisap, conveyor | Bendera cocok untuk festival |
| `FX` | Serangan (slash, cut, claw), elemen (api, es, petir, air, tanah, ledakan), sihir (aura, perisai, spark), **proyektil shuriken & kunai**, **asap**, partikel (bambu, daun, hujan, kabut) | Siap untuk Nadiya dan Farah |
| `Items` | 140 item: makanan (Noodle, Onigiri, Sushi, TeaLeaf, Yakitori, dll.), gulungan 7 jenis, ramuan, kunci, harta, 23 jenis senjata | Cukup untuk hadiah dan quest |
| `Audio` | 40 musik, 15 jingle, ~130 SFX (menu, hit, slash, magic, ambient, voice, creature) | Tidak ada SFX ayam |
| `Ui` | Kotak dialog + faceset, ikon skill (hook, kunai, shuriken, kunci, masak), emote 30, hint keyboard/gamepad/mouse, tema kayu, font piksel | Cocok untuk HUD dan dialog |

Lisensi: **CC0**. Boleh dipakai komersial, atribusi tidak wajib (tetap kita cantumkan di kredit).

---

## 2. Keputusan teknis dan arsitektur

### 2.1 Prinsip
1. **Data-driven.** Cerita, dialog, quest, dan puzzle ada di file data (JSON/`.tres`), bukan di dalam skrip. Menambah Act = menambah data + peta, bukan menulis ulang kode.
2. **Satu format karakter.** Semua orang (Arka, partner, NPC, musuh kecil) memakai `SpriteCharacter` yang sudah ada, jadi 95 karakter pack langsung bisa dipakai.
3. **Ramah anak.** Tidak ada kematian dan darah. Kalah = "pingsan", bangun di rumah Hokage dan disembuhkan Dokter Zahra (sesuai brief). Musuh kalah = "puff" asap + bintang pusing.
4. **Kompatibel web sejak hari pertama.** Renderer Compatibility, tanpa thread, tanpa fitur khusus desktop, ukuran build dijaga.
5. **Salin aset secukupnya.** Hanya aset yang dipakai yang disalin ke repo (`assets/`) dengan manifest sumber. Pack penuh tidak masuk repo, agar repo dan build web tetap kecil.

### 2.2 Struktur folder usulan (`res://`)
```
assets/            aset terpilih dari pack + hasil generate (dengan SOURCES.md)
  generated/       hasil skrip (tidak diedit tangan)
content/
  acts/act01..act10/   peta, quest.json, dialog.json, puzzle.json, musuh
  characters/      arka, bida, nadiya, farah, npc/
  enemies/  bosses/  items/  gadgets/
system/            engine: character, weapon, damage, map, ... (sudah ada) + baru
  party/ dialogue/ quest/ puzzle/ save/ ui/ boss/ interact/ audio/
tools/             skrip Python (generate aset), linter konsistensi brief, validator data
docs/              Story Bible, desain per Act, daftar puzzle, QA checklist
```

### 2.3 Autoload (singleton)
| Nama | Tugas |
|---|---|
| `GameState` | Flag cerita, Act berjalan, inventori, hati, anggota party, item kunci |
| `SaveSystem` | Simpan/muat ke `user://` (di web tersimpan di IndexedDB browser), autosave di titik aman |
| `Dialogue` | Memutar dialog dari data: pembicara, faceset, emote, pilihan, kondisi flag, efek ketik + bunyi "voice" per karakter |
| `Quests` | Objektif utama dan side quest, pelacak di HUD, trigger dan kondisi selesai |
| `Audio` | Bus musik/SFX, crossfade musik per area, jingle |
| `Scenes` | Pindah peta dengan transisi, titik muncul (spawn point), memori posisi partner |
| `MathPuzzles` | Bank soal, panel soal, kertas coretan, petunjuk bertingkat, catatan jawaban |
| `Settings` | Volume, ukuran teks, mode santai, kontrol |

### 2.4 Sistem party (Arka + 3 partner)
Pemain mengendalikan **Arka**. Bida, Nadiya, Farah adalah partner AI (rekomendasi brief bagian 7).

- **Mengikuti:** formasi di belakang Arka, memakai `behavior_follow.gd` yang sudah ada; teleport menyusul jika tertinggal atau macet; tidak boleh menghalangi pintu.
- **Perintah sederhana** (3 tombol, atau roda kecil): Bida = *Analisis* (tahan: titik lemah musuh dan petunjuk puzzle menyala), Nadiya = *Bidik/Tembak* (tembak target yang disorot), Farah = *Gadget* (bom asap, detektor, perbaiki mesin, grappling hook di tempat berpengait).
- **Interaksi kontekstual:** mendekati objek memunculkan ikon "siapa yang bisa membantu" (sakelar jauh = Nadiya, mesin = Farah, pola = Bida).
- **Pindah karakter** hanya di momen set-piece tertentu (mis. Act 6 dan 9, saat tim berpencar). Tidak dibuat sebagai sistem umum agar cakupan terjaga.
- Aturan desain wajib dari brief: **tidak ada rintangan yang bisa diselesaikan Arka sendiri** di Act 2 ke atas; tiap Act punya penanda kontribusi 4 karakter (dicek di checklist QA).

### 2.5 Pertarungan
- Arka: serang jarak dekat (sistem `Weapon` yang ada), **dash**, **counter** (jendela waktu singkat), hati (bukan HP angka).
- Musuh: patroli, kejar, serangan dengan aba-aba (telegraph) jelas, jatuhkan makanan penyembuh.
- **Kerangka boss**: mesin status (state machine), fase, titik lemah yang disingkap Bida dan ditembak Nadiya, pola berulang yang bisa dibaca anak-anak.
- Mode Santai: lebih banyak hati, serangan musuh lebih lambat, boleh melewati pertarungan non-boss.

### 2.6 UI
Dialog (kotak + faceset dari pack), pelacak quest, HUD hati + ikon 3 kemampuan partner, menu jeda, layar judul, pengaturan, panel soal matematika, peta mini/penanda objektif (opsional), kontrol sentuh (diadaptasi menjelang rilis episode pertama, Fase 8b). Sejak awal semua tombol/area UI dibuat cukup besar dan tidak bergantung pada hover agar mudah dipindah ke layar sentuh.

### 2.7 Bahasa
Game **dua bahasa: Indonesia (bahasa sumber, sesuai brief) dan Inggris**, dengan pilihan di Pengaturan dan di layar judul.
- Semua teks (dialog, quest, nama item, UI, **soal matematika**, petunjuk, penjelasan) disimpan sebagai **kunci terjemahan** (file JSON `translations/<area>.<bahasa>.json`, dimuat ke `TranslationServer` oleh autoload `Settings`; JSON dipilih karena file CSV tidak ikut ter-export apa adanya) sejak Fase 0. Tidak ada teks cerita yang ditulis langsung di skrip atau scene.
- Nama baku dari brief **tidak diterjemahkan**: Desa Daun, Arka, Bida, Nadiya, Farah, Hokage Pak Hilmi, Dokter Zahra, Kuro, Mesin Keseimbangan Desa, Proyek Hokage Abadi. Versi Inggris memakai nama yang sama dan menjelaskan lewat dialog bila perlu. Kata "Konoha" tetap terlarang.
- Judul: ID **"Petualangan Arka di Kampung Ninja"**; EN usulan sementara **"Arka's Adventure in Ninja Village"** (bisa diubah).
- Font piksel pack hanya mencakup huruf Latin; cukup untuk ID dan EN. Teks Inggris lebih panjang/pendek, jadi kotak dialog dan UI dirancang fleksibel.
- Linter brief memeriksa **kedua** bahasa dan memastikan setiap kunci punya terjemahan ID dan EN.
- Soal matematika disusun dua bahasa. Format angka mengikuti bahasa (ID: `1.000,5`; EN: `1,000.5`), dan keypad menerima kedua gaya desimal.

### 2.8 Verifikasi dan kualitas
- **Linter konsistensi brief** (`tools/lint_brief.py`): gagal jika ada kata "Konoha", salah ejaan nama Arka/Bida/Nadiya/Farah/Kuro/Pak Hilmi/Desa Daun, atau kata/gambaran terlarang (darah, mati eksplisit).
- **Validator data**: setiap quest, dialog, puzzle merujuk ID yang ada; setiap puzzle punya jawaban, 3 petunjuk, dan penjelasan.
- **Smoke test** Godot (`--headless`) yang memuat semua peta dan menjalankan beberapa frame, untuk menangkap error skrip/resource.
- **Penting:** Godot yang ada adalah `.exe` Windows, sedangkan saya bekerja di VM Linux. Untuk **menjalankan dan melihat game** saya perlu salah satu: (a) sesi Remote Control di PC Anda, atau (b) Godot Linux di VM (bergantung izin jaringan). Ini dibahas di Fase 0 dan bagian 9.

---

## 3. Peta aset: fitur → aset pack

Path relatif terhadap `Ninja Adventure - Asset Pack\Ninja Adventure - Asset Pack\`.

### 3.1 Karakter inti dan NPC
| Kebutuhan | Basis di pack | Perlu diubah? |
|---|---|---|
| **Arka (L)** | `Actor/Character/NinjaGreen` atau `NinjaRed`, + senjata `Items/Weapons/Katana` (opsional `CharacterAnimated/NinjaGreen` untuk roll/climb) | Recolor + ikat kepala; faceset khas |
| **Bida (P)** | `NinjaBlue` / `NinjaBlue2` | Kacamata, kuncir, gulungan; faceset |
| **Nadiya (P)** | `NinjaRed2` / `NinjaYellow` | Busur/ransel kunai, ikat rambut; faceset |
| **Farah (P)** | `NinjaYellow` / `NinjaBomb` | Goggle, ransel gadget; faceset |
| **Pak Hilmi** | `Master` / `OldMan2` / `Monk` | Topi/jubah Hokage; faceset |
| **Dokter Zahra** | `Woman` / `Princess` | Jas putih, ikon palang; faceset |
| **Kuro** | `NinjaDark` / `NinjaMageBlack` | Syal ungu, simbol mata spiral |
| **Kapten Topeng + anak buah** | `NinjaMasked`, `NinjaGray`, `Samurai` | Palet seragam |
| **Warga desa, kakek kostum naga, pedagang** | `Villager`..`Villager6`, `Village6`, `OldMan/2/3`, `OldWoman`, `Child`, `Hunter`, `Noble` | Cukup pakai langsung |
| **Ninja pengembara (Act 7)** | `NinjaEskimo`, `NinjaWater`, `NinjaFire`, `NinjaThunder` | Pakai langsung |

### 3.2 Musuh dan boss per Act
| Act | Musuh/boss (brief) | Basis di pack | Status |
|---|---|---|---|
| 1 | **Ayam Ninja** | `Actor/Animal/Chicken` (4 warna) | Sheet kecil (32x16); perlu diperbesar, ikat kepala ninja, animasi lari |
| 2 | **Lendir Raksasa** (membelah) + slime | `Boss/GiantSlime`, `GiantSlime2`, `Monster/Slime..Slime4` | Recolor **ungu**; logika membelah dari kode |
| 3 | **Babi Hutan Bertopeng**, jamur bersin, bambu hidup | `Animal/WildBoar`, `Monster/Mushroom(2)`, `Monster/Bamboo(Yellow)`, `Boss/GiantBamboo` | Topeng ninja kekecilan = overlay buatan |
| 4 | **Boneka Samurai Raksasa**, boneka latihan, gerobak dango | `Boss/GiantBlueSamurai` / `GiantRedSamurai`, `Character/Statue` | Gerobak dan boneka latihan perlu dibuat |
| 5 | **Kapten Topeng** (bersin) + ninja bertopeng | `Character/NinjaMasked`, `Samurai*` | Animasi/emote bersin = emote + kode |
| 6 | **Golem Chakra** | `Boss/GiantSpirit`, `Character/Statue`, `GoldStatue`, `RobotGrey` | Gabungan/skala + efek retak |
| 7 | **Kucing Petir raksasa** + kucing liar | `Animal/Cat*` (5 warna), `FX/Elemental/Thunder` | Versi raksasa perlu dibuat (skala + petir) |
| 8 | **Kuro, Mode Ninja Bayangan** | `Character/NinjaDark` | Klon peniru gerakan = kode (rekam input lalu putar ulang) + shader bayangan |
| 9 | **Hokage Abadi** (robot raksasa) + penjaga inti | `Character/Robot*`, `Boss/DemonCyclop`, `TilesetTowers` | Perlu **dibuat/gabung** (zirah + kristal) |
| 10 | **Bayangan Arka**, inti terakhir | Sprite Arka + shader gelap, `Boss/GiantSpirit` | Shader + overlay |

### 3.3 Dunia (tileset) per lokasi
| Lokasi | Tileset utama |
|---|---|
| Desa Daun, pasar, alun-alun | `TilesetField`, `TilesetFloor(B/Detail)`, `TilesetHouse` (rumah, dojo, torii, kios), `TilesetElement` (tong, kotak, lentera), `TilesetNature`, bendera `Animated/Flag` |
| Sumur, saluran air, gua mata air | `TilesetWater`, `Pipes`, `TilesetDungeon`, `TilesetHole`, `Animated/Water Ripples` (varian ungu sudah ada), `Waterfall` |
| Hutan bambu | `TilesetNature`, `FX/Particle/Bamboo`, `Leaf`, `Raylight`, `Fog` |
| Akademi ninja lama | `TilesetVillageAbandoned`, `Interior/*`, `TilesetWallSimple`, `TilesetHouse` |
| Pegunungan utara | `TilesetRelief(Detail)`, `TilesetNature`, snow (Part 2 aset), jembatan gantung (cek `TilesetRelief`/`Floor`) |
| Lab bawah tanah, Menara Chakra | `TilesetDungeon`, `Pipes`, `TilesetLogic`, `TilesetTowers`, `Animated/Conveyor Belt` |

### 3.4 Mekanik → aset
| Mekanik | Aset |
|---|---|
| Shuriken/kunai Nadiya | `FX/Projectile/Shuriken`, `FX/Projectile/Kunai`, `Items/Projectile` |
| Bom asap Farah | `FX/Smoke/Smoke`, `SmokeCircular` |
| Grappling hook, detektor | ikon `Ui/Skill Icon/Items & Weapon/Hook`; sprite gadget dibuat |
| Analisis Bida | `FX/Magic/Aura`, `Circle`, `Spark`; ikon skill |
| Efek lendir/air/sabun | `FX/Elemental/Water`, `Particle/*`, SFX `Bubble` |
| Petir, ledakan, kembang api | `FX/Elemental/Thunder`, `Explosion`, `Particle/Spark` |
| Hadiah dan quest | `Items/Scroll`, `Food`, `Treasure`, `Resource`, kunci `Ui/Skill Icon/Job & Action/Key0..7` |
| Dialog | `Ui/Dialog/*`, `Ui/Font/NormalFont.ttf`, `Ui/Emote/*` (30), faceset tiap karakter |
| Voice blip dialog | `Audio/Sounds/Voice` (10) diberi nada berbeda per karakter |
| Hint tombol | `Ui/Input/Keyboard`, `Gamepad`, `Mouse` |

### 3.5 Musik (usulan berdasarkan judul; **belum didengarkan**, perlu uji telinga di Fase 8)
| Konteks | Lagu |
|---|---|
| Judul | `38 - Intro`, `1 - Adventure Begin` |
| Desa Daun, pasar | `33 - Calm Village`, `31 - Sunny`, `36 - Village`, `4 - Village` |
| Kejar-kejaran / eksplorasi | `35 - Adventure`, `20 - Good Time`, `23 - Road` |
| Saluran air, gua | `18 - Aquatic`, `2 - The Cave`, `13 - Mystical` |
| Hutan | `11 - Clearing`, `37 - Dark Forest` (ringan), `13 - Mystical` |
| Festival | `20 - Good Time`, `4 - Village` → `28 - Tension` saat kacau |
| Akademi | `32 - Manor`, `12 - Temple`, `9 - Quiet` (stealth) |
| Krisis desa | `29 - Lament`, `28 - Tension` |
| Gunung | `19 - Ascension`, `23 - Road`, `21 - Dungeon` |
| Lab / Kuro | `21 - Dungeon`, `40 - Crypt`, `24 - Final Area` |
| Menara / final | `24 - Final Area`, `17/34 - Fight` |
| Penutup | `3 - Revelation`, `8 - End Theme`, `25 - End Theme 2`, `15 - Credit Theme` |
| Jingle | `Jingles/Success*`, `Secret*`, `LevelUp*`, `GameOver*` (diganti nada ringan "pingsan", bukan sedih) |

---

## 4. Aset yang kurang dan cara membuatnya

**Metode utama: skrip Python + PIL** (`tools/gen_*.py`) yang memakai sprite pack sebagai basis: recolor palet, tambah overlay piksel (ikat kepala, kacamata, topeng), skala bilangan bulat, dan menyusun sheet dengan format yang sama. Alasannya: gaya pack 16x16 dan palet terbatas (`Palette.png`); gambar AI biasanya tidak patuh grid piksel dan palet sehingga terlihat tidak menyatu. Skrip bisa diulang jika Anda ingin mengubah warna.
Python dan PIL sudah tersedia di lingkungan saya.

| # | Aset | Cara | Prioritas |
|---|---|---|---|
| A1 | Sprite sheet + faceset **Arka, Bida, Nadiya, Farah** (+ emote per karakter) | Recolor + overlay dari ninja pack; perlu mudah dibedakan, dan dibaca sebagai putra/putri tanpa mengubah format sheet | **Fase 2** |
| A2 | **Pak Hilmi**, **Dokter Zahra**, **Kuro**, **Kapten Topeng** | Recolor + overlay (topi Hokage, jas putih, syal ungu) | Fase 2 / 6 |
| A3 | **Ayam Ninja** (besar, ikat kepala, animasi lari 4 arah) | Skala 2x dari ayam pack + overlay + frame tambahan | Fase 6 |
| A4 | Prop Act 1: **bubur ungu** (mangkuk ramen, genangan, jejak lendir), gulungan latihan, sarang ayam, sandal | Recolor item `Noodle`, tile genangan; sandal digambar dengan skrip (16x16) | Fase 6 |
| A5 | Simbol **mata spiral** (dinding, topeng, mesin, 3 ukuran) dan **kristal pengatur energi** (3 warna) | Digambar oleh skrip; cek dulu kristal pada `Items/Resource` dan `Treasure` | Fase 6 / 7 |
| A6 | UI **kertas coretan**, pensil, penghapus, tombol angka (keypad) | Digambar (nine-patch kertas, ikon) dengan palet tema kayu | **Fase 5** |
| A7 | Judul/logo **"Kampung Ninja"** dan ikon game | Font piksel 24x30 di pack (`font24x30.png`) + hiasan shuriken | Fase 2 |
| A8 | Ikon kemampuan partner: Analisis, Bidik, Gadget (+ varian ketika cooldown) | Turunan dari `Ui/Skill Icon` | Fase 3 |
| A9 | Gadget Farah: bom asap (item), detektor lendir, penyeimbang | Gambar skrip + FX pack | Fase 3 |
| A10 | Act 2–4: gerobak dango, dango, kostum naga, boneka latihan, kembang api, simbol festival | Skrip + recolor; kembang api dari `FX/Particle/Spark` | Fase 7 (per Act) |
| A11 | Babi Bertopeng, jamur bersin (animasi bersin), Kucing Petir raksasa, bola benang | Skala + overlay + FX petir | Fase 7 |
| A12 | **Golem Chakra**, **Hokage Abadi**, **Bayangan Arka**, inti mesin, perangkat pengendali | Gabungan sprite robot/patung + kristal; bayangan = shader | Fase 7 (Act 6, 9, 10) |
| A13 | SFX **kokok ayam** dan beberapa bunyi lucu (bersin, "boing" prototipe Farah) | Pitch-shift/susun dari SFX pack; atau sintesis sederhana | Fase 8 |
| A14 | Ilustrasi cutscene statis pembuka/penutup | **Opsional.** Saya sarankan cutscene dalam engine (kamera, emote, dialog) supaya gaya seragam | Opsional |

**Aset yang perlu diverifikasi dulu** (belum saya buka satu per satu): apakah ada sumur, jembatan gantung, kristal, dan boneka latihan yang bisa dipakai langsung di tileset/item pack. Saya akan memeriksanya di awal Fase 1 sebelum memutuskan apa yang dibuat.

---

## 5. Fase pengerjaan

Ukuran: **S** kecil, **M** sedang, **L** besar, **XL** sangat besar. Setiap fase = satu branch + PR draft untuk Anda review. Ada **gerbang persetujuan (🚪)** sebelum lanjut.

### Fase 0 — Fondasi proyek (M)
Tujuan: proyek bersih, siap web, dan bisa saya jalankan serta uji.
- [ ] Jalur menjalankan Godot: **Remote Control di PC Anda (sudah Anda setujui)**; pasang smoke test dan pengambilan screenshot lewat jalur ini.
- [ ] Hapus file `.tmp`, ganti nama proyek, naikkan `config/features` ke 4.7, ganti renderer ke **Compatibility**, periksa shader `color_correction` dan partikel masih tampil benar.
- [ ] Susun struktur folder (bagian 2.2), tambah `assets/SOURCES.md` dan salin `LICENSE.txt` CC0.
- [ ] Input map baru: `attack`, `dash`, `interact`, `ability_1/2/3`, `pause`, `scratchpad`, dengan hint keyboard dan gamepad.
- [ ] Autoload kosong (bagian 2.3) + alur `Main` → Title → Game.
- [ ] **Kerangka multi-bahasa:** `translations/*.id.json` dan `*.en.json` (kunci → teks), pemilih bahasa di `Settings`, aturan "tidak ada teks hard-coded".
- [ ] Ganti nama proyek menjadi **Petualangan Arka di Kampung Ninja** (`project.godot`, ikon/judul jendela).
- [ ] Skrip `tools/lint_brief.py`, validator data, smoke test headless.
- [ ] Cek ketersediaan **export template** web (lihat risiko R3).
- [ ] Kebijakan git: branch per fase, PR draft, pesan commit jelas.
**Selesai jika:** game sample tetap jalan di Compatibility, smoke test hijau, struktur siap.

### Fase 1 — Story Bible dan desain Act 1 (M) — *dokumen saja*
Mengikuti urutan prioritas di brief bagian 10 (langkah 1–3).
- [ ] Verifikasi aset yang masih ragu (bagian 4, akhir) lalu finalkan peta aset.
- [ ] **Game Story Bible ringkas** (`docs/story_bible.md`): nama baku, karakter, nada humor, daftar larangan, linimasa 10 Act, benang merah petunjuk (mata spiral → mesin → Kuro).
- [ ] Desain **Act 1** memakai template 12 poin (bagian 8 brief): quest utama, 2–4 side quest, dialog, musuh/boss Ayam Ninja, kontribusi 4 karakter, hadiah, petunjuk, cliffhanger, catatan implementasi.
- [ ] Daftar NPC, item, puzzle, dan boss Act 1; 2 puzzle matematika Act 1 lengkap.
- [ ] Rancang **kurva kesulitan matematika** untuk 10 Act (bagian 7).
**🚪 Gerbang 1:** Anda menyetujui Story Bible dan desain Act 1 sebelum kode dibuat.

### Fase 2 — Inti game: Arka, dunia, dialog (L)
- [ ] Generate aset **A1, A2 (Pak Hilmi, Dokter Zahra), A7**; pasang Arka sebagai pemain.
- [ ] Gerak, **serang, dash, counter**, hati, pingsan dan bangun di rumah Hokage; senjata Katana.
- [ ] Sistem **interaksi** (area + ikon tombol), objek bisa dibaca, peti, pintu, kunci.
- [ ] **Sistem dialog** (kotak + faceset + emote + pilihan + kondisi flag) dan bunyi ketik per karakter.
- [ ] Pindah peta dengan spawn point dan transisi; `GameState`; **save/load** + autosave.
- [ ] Layar judul, menu jeda, pengaturan (volume, ukuran teks, mode santai, **bahasa Indonesia/Inggris**).
- [ ] HUD (hati, objektif aktif); `Audio` dengan crossfade per area.
**Selesai jika:** Anda bisa berjalan di desa uji, bicara dengan NPC, bertarung dengan boneka latih, save dan load.

### Fase 3 — Partner dan kemampuan tim (L)
- [ ] Generate **A1 (Bida, Nadiya, Farah)**, **A8, A9**.
- [ ] Partner AI: mengikuti, formasi, menyusul, tidak macet di pintu/teleporter.
- [ ] **Analisis (Bida)**: sorot titik lemah, petunjuk puzzle, jejak.
- [ ] **Bidik/Tembak (Nadiya)**: pilih target, proyektil shuriken/kunai, mengenai sakelar jauh dan musuh terbang.
- [ ] **Gadget (Farah)**: bom asap (mengalihkan musuh), detektor, perbaikan mesin, grappling hook di titik pengait.
- [ ] Blok puzzle dasar: sakelar, tekan-lantai, pintu mekanis, pintu kunci, katup air, soket kristal, perangkap.
- [ ] Dialog "celetukan" partner (lucu, singkat) saat idle atau mendekati objek.
**Selesai jika:** ada satu ruang uji yang hanya bisa diselesaikan dengan ketiga partner.

### Fase 4 — Musuh dan kerangka boss (L)
- [ ] AI musuh dasar (patroli, kejar, serang dengan aba-aba), spawn kelompok, makanan penyembuh.
- [ ] **Kerangka boss**: fase, titik lemah, pola, tanda bahaya, rangkaian jingle.
- [ ] Efek "puff" saat musuh kalah (tanpa darah), efek getar ringan dan hit-stop.
- [ ] Seleksi aset musuh/boss yang akan dipakai (bagian 3.2) dan siapkan template scene.
- [ ] Boss uji (mis. GiantSlime) untuk memvalidasi kerangka.
**Selesai jika:** satu boss uji punya 2 fase, titik lemah, dan bisa dikalahkan dengan kerja sama.

### Fase 5 — Puzzle matematika dan kertas coretan (M–L)
- [ ] **Skema soal** (`puzzle.json`): id, Act, kelas, topik, cerita, jawaban (angka/pecahan/desimal), format yang diterima, 3 petunjuk bertingkat dari Bida, penjelasan solusi, hadiah.
- [ ] **Panel soal**: teks cerita, keypad angka, tombol cek, umpan balik lucu (salah ≠ hukuman; boleh ulang tanpa batas).
- [ ] **Kertas coretan**: kanvas gambar berbasis input pointer. **Saat pengembangan memakai mouse**; Godot dapat mengubah sentuhan menjadi input mouse, jadi di HP nanti cukup diuji dan disesuaikan ukuran tombolnya di Fase 8b. Pensil/penghapus/hapus semua, bisa dibuka kapan saja saat puzzle; tetap terlihat saat mengetik jawaban.
- [ ] Integrasi cerita: soal dipicu objek (kunci angka, katup, kasir, timer) bukan menu terpisah.
- [ ] Mode **tanpa tekanan waktu** kecuali puzzle bertema waktu; opsi petunjuk gratis.
- [ ] Validator: setiap soal diselesaikan ulang oleh skrip untuk memastikan jawaban benar.
- [ ] Generate **A6**.
**Selesai jika:** 4 soal contoh (kelas 3, 4, 5) berjalan dalam ID dan EN, coretan berfungsi dengan mouse (uji layar sentuh nanti di Fase 8b).

### Fase 6 — Vertical slice: Act 1 lengkap (L–XL)
"Mimpi Besar, Sandal Hilang" (tutorial, ketegangan 1/10).
- [ ] Peta Desa Daun (rumah Hokage dengan Dokter Zahra, akademi/lapangan ujian, pasar kecil, gudang ramen, jalur ke saluran air).
- [ ] Generate **A3, A4, A5 (awal)**; NPC bernama dengan kebiasaan dan side quest lucu.
- [ ] Ujian ninja pemula: 3 gulungan latihan; pengejaran ayam dengan peran Bida (strategi), Nadiya (tembak jarak jauh), Farah (alat pelacak yang mengejar sandal).
- [ ] Boss **Ayam Ninja** (ternyata hanya melindungi sarang: akhir yang damai).
- [ ] Pidato Pak Hilmi (Festival Seribu Shuriken) → gudang ramen jadi bubur ungu → jejak lendir → cliffhanger.
- [ ] 2 puzzle matematika Act 1, hadiah shuriken pertama, akses bebas desa.
- [ ] Musik, SFX, humor (ayam lebih cepat dari ninja pemula, alat Farah salah sasaran, Pak Hilmi takut ayam).
- [ ] QA memakai checklist brief bagian 9; perbaikan dari uji main.
**🚪 Gerbang 2 (penting):** Anda memainkan Act 1 dan memutuskan: gaya visual, tingkat kesulitan, panjang durasi, apakah pola ini dilanjutkan untuk 9 Act berikutnya.

### Fase 7 — Produksi Act 2–10 (XL, berulang)
Setiap Act memakai alur yang sama: desain (template 12 poin) → persetujuan singkat → peta + data → mekanik baru → musuh/boss → 2+ puzzle matematika → QA checklist brief → PR.
Kelompok kerja (tiap kelompok = satu gerbang review) dan sekaligus **episode rilis** (bagian 5.1):

| Kelompok | Act | Isi utama | Mekanik baru |
|---|---|---|---|
| **A: Desa dan sekitarnya** (Episode 1 = Act 1–4) | 2, 3, 4 | Sumur dan saluran air, hutan bambu, festival | Teka-teki aliran air (Bida), sakelar tersangkut (Nadiya), mesin tua (Farah), misi bertimer menyelamatkan warga, boss membelah/menyeruduk/berhenti saat musik |
| **B: Akademi dan krisis** (Episode 2) | 5, 6, 7 | Akademi terkunci, desa kehilangan chakra, gunung | **Stealth** (kerucut pandang), kunci dan jebakan, **pertahanan area dengan pembagian tugas**, traversal (jembatan gantung, gua, grappling hook), pengalih perhatian (bola benang) |
| **C: Klimaks** (Episode 3) | 8, 9, 10 | Laboratorium Kuro, Menara Chakra, finale dan epilog | Klon peniru, puzzle multi-area dengan 3 inti, boss multi-fase, **pilihan menolak godaan kekuatan tunggal**, upacara, adegan setelah kredit (ayam + kristal ungu) |

Rincian per Act ada di bagian 6.

### Fase 8 — Polesan, keseimbangan, aksesibilitas (L, dilakukan per episode)
- [ ] Uji main berurutan seluruh Act dalam episode, atur kurva kesulitan; Mode Santai dan opsi petunjuk.
- [ ] Pass **ramah anak**: periksa kata, efek, tingkat "seram" tiap Act; baca ulang semua dialog agar singkat dan mudah dipahami; copyedit Bahasa Indonesia **dan terjemahan Inggris** (humor dan kalimat khas tiap karakter harus terjaga di EN).
- [ ] Pass humor: tiap Act punya minimal satu momen lucu yang alami; konsistensi karakter (kalimat khas Bida, Nadiya, Farah, Arka).
- [ ] Musik: dengarkan semua usulan di bagian 3.5, ganti yang tidak cocok; SFX tambahan (A13); mix volume.
- [ ] Aksesibilitas: ukuran teks, kontras, kecepatan teks, jangan mengandalkan warna saja, tombol bisa diatur ulang.
- [ ] Performa (frame time, memori, ukuran), uji di browser dan perangkat modest.
- [ ] Linter brief, validator data, dan checklist QA dijalankan pada seluruh game.
- [ ] Kelengkapan terjemahan: semua kunci punya ID dan EN, tidak ada teks meluap di kotak dialog/UI pada kedua bahasa.
**🚪 Gerbang 3 (per episode):** Anda menyatakan episode ini siap rilis.

### Fase 8b — Adaptasi layar sentuh dan HP/tablet (M) — *sebelum rilis episode pertama*
- [ ] **Virtual joystick** + tombol aksi (serang, dash, interaksi, 3 kemampuan partner, jeda), bisa disembunyikan, otomatis muncul di perangkat sentuh.
- [ ] Skala UI untuk layar kecil (dialog, quest, panel soal, keypad, kertas coretan) dan orientasi lanskap.
- [ ] Kertas coretan dengan jari: tebal garis, tolak telapak tangan (jika perlu), tombol hapus/undo besar.
- [ ] Petunjuk tombol berganti otomatis (keyboard/gamepad/sentuh).
- [ ] Uji di browser ponsel dan tablet (Android Chrome dan iOS Safari), termasuk kinerja dan audio.

### Fase 9 — Rilis dan deploy GitHub Pages (M, berulang per episode) — *hanya setelah Gerbang 3 episode tersebut*
- [ ] Export **Web** (renderer Compatibility, **tanpa thread** supaya jalan di GitHub Pages yang tidak mengirim header COOP/COEP), kompresi, anggaran ukuran.
- [ ] Penanganan audio (butuh klik pertama), layar penuh, pengubahan ukuran canvas, tampilan di ponsel/tablet.
- [ ] Workflow GitHub Actions: build web → deploy ke Pages (`.nojekyll`, branch `gh-pages` atau Pages Actions).
- [ ] Uji di Chrome, Firefox, Safari; save di IndexedDB; uji kembali kertas coretan di layar sentuh.
- [ ] README (Indonesia dan Inggris), kredit (Pixel-boy & AAA, CC0), nomor versi per episode, opsional build Windows.
- [ ] Layar akhir episode "Bersambung…" (Episode 1 dan 2), pesan lembut, dan tautan ke bagian berikutnya.
- [ ] Pastikan **save lama tetap terbaca** saat episode berikutnya dirilis (versi format save + migrasi).
- [ ] Rilis pertama = menyiapkan seluruh pipeline Pages; rilis berikutnya tinggal menambah Act.

### 5.1 Rilis bertahap per episode
Brief membagi cerita menjadi 10 Act dengan cliffhanger di setiap Act, sehingga mudah dipotong menjadi episode yang berdiri sendiri:

| Episode | Act | Cerita | Akhir episode |
|---|---|---|---|
| **1** | 1–4 | Ayam, ramen ungu, sumur, hutan bambu, festival kacau | Tiga kristal hilang, simbol mata spiral muncul |
| **2** | 5–7 | Akademi terkunci, desa kehilangan chakra, Gunung Kucing Petir | Proyek Hokage Abadi terungkap, Kuro bersiap |
| **3** | 8–10 | Rahasia Kuro, Mesin mengamuk, finale dan epilog | Tamat + adegan setelah kredit |

- Tiap episode melewati Fase 8 (polesan), 8b/9 (hanya yang belum), dan Gerbang 3 sendiri.
- Episode 1 diperlakukan sebagai **rilis publik pertama**: semua sistem inti (dialog, party, boss, matematika, save, dua bahasa, sentuh) sudah matang, jadi episode berikutnya hanya konten.
- Konsekuensi: Fase 7 kelompok A harus mencapai kualitas rilis lebih dulu; kelompok B dan C dikerjakan setelah Episode 1 diumumkan (atau paralel jika Anda mau).
- Kurikulum matematika tiap episode tetap utuh (Episode 1 ≈ kelas 3–4, Episode 2 ≈ kelas 4, Episode 3 ≈ kelas 5), jadi anak yang berhenti di Episode 1 tetap mendapat bahan kelas 3–4.

---

## 6. Rencana per Act (ringkas)

Semua Act mengikuti template 12 poin brief dan checklist bagian 9. Berikut peta teknisnya. Puzzle matematika diberi ide awal; soal final ditulis di Fase 1/7 dan dicek ulang oleh validator.

| Act | Lokasi/tileset | Boss & basis aset | Peran tim (inti) | Mekanik baru | 2 puzzle matematika (ide) | Aset yang perlu dibuat |
|---|---|---|---|---|---|---|
| **1** Mimpi Besar, Sandal Hilang | Desa Daun (Field, House, Element) | Ayam Ninja (`Animal/Chicken`) | Bida rencana kejar, Nadiya tembak, Farah pelacak | Dasar: gerak, serang, interaksi, dialog | Hitung shuriken latihan (perkalian + tambah); sisa mangkuk ramen (kurang 3 digit) | A1–A4 |
| **2** Misteri Sumur | Pasar, sumur, saluran (Water, Pipes, Dungeon) | Lendir Raksasa (`GiantSlime`, ungu) | Bida pola aliran, Nadiya sakelar, Farah detektor lendir | Teka-teki aliran air, boss membelah | Bagi ember ke stan (pembagian); jumlah liter dari 3 pipa (tambah) | Simbol mata spiral, detektor |
| **3** Hutan Bambu Kesurupan | Hutan, gua mata air (Nature, Water) | Babi Hutan Bertopeng (`WildBoar`) | Bida baca pola seruduk, Nadiya titik lemah, Farah mesin | Musuh berkelompok, rintangan lingkungan | Satuan panjang/berat (cm-m, g-kg); pola bilangan | Topeng, jamur bersin |
| **4** Festival jadi Bencana | Alun-alun (House, Flag) | Boneka Samurai Raksasa (`GiantBlueSamurai`) | Arka selamatkan warga, Bida urutan penanganan, Nadiya pemicu, Farah wahana | Misi bertimer, wahana | Uang & kembalian dango; waktu (jam + menit) kembang api | Gerobak dango, kostum naga |
| **5** Akademi Terkunci | Akademi (VillageAbandoned, Interior) | Kapten Topeng (`NinjaMasked`) | Bida kombinasi, Nadiya sakelar tinggi, Farah kunci | Stealth, kunci, perangkap | KPK/FPB kunci kombinasi; keliling & luas ruang jebakan | Catatan sejarah, topeng |
| **6** Desa Kehilangan Chakra | Seluruh desa (gelap/listrik padam) | Golem Chakra (`Statue`/`GiantSpirit`) | Keempat berpencar menjaga area | Pertahanan area, pembagian tugas, mati lampu | Pecahan listrik yang pulih (¾, 2/3 ...); pembagian sisa warga ke tempat perlindungan | Golem, sandal klon, teh |
| **7** Gunung Kucing Petir | Gunung (Relief, Nature, snow) | Kucing Petir raksasa (`Cat*` + petir) | Bida rencana, Nadiya serang jauh, Farah pengalih | Traversal, jembatan, gua perangkap, bola benang | Kecepatan–jarak–waktu (jembatan); skala peta | Kucing raksasa, bola benang |
| **8** Rahasia Kuro | Lab bawah tanah (Dungeon, Pipes, Logic) | Kuro Ninja Bayangan (`NinjaDark`) | Bida pola klon, Nadiya inti asli, Farah matikan pengendali | Boss peniru gerakan | Rata-rata; perbandingan (klon 3:2) | Kuro, perangkat pengendali |
| **9** Mesin Mengamuk | Menara Chakra (Towers, Dungeon) | Hokage Abadi (robot, `Robot*`) | Tim berpencar menonaktifkan 3 inti | Puzzle multi-area, boss multi-fase, kristal serentak | Volume balok (tangki); pecahan desimal/persen | Hokage Abadi, inti, kristal |
| **10** Hokage yang Tak Menyerah | Inti mesin, Desa Daun | Bayangan Arka (shader + sprite Arka) | Semua kemampuan + bantuan warga dan Kuro | Kombinasi, pilihan tidak sendirian | Gabungan (pembulatan, operasi campuran) bertingkat | Bayangan, upacara, mangkuk |

Catatan: judul dan urutan Act tidak diubah dari brief.

---

## 7. Puzzle cerita matematika (kelas 3–5 SD)

- **Syarat dari brief:** minimal 2 puzzle per Act, soal cerita, dengan kertas coretan. Total target **20+ puzzle** (disarankan 24–30 agar ada variasi dan opsi ulang).
- **Kurva kesulitan:** Act 1–3 ≈ kelas 3 (penjumlahan/pengurangan sampai 1.000/10.000, perkalian-pembagian dasar, satuan, uang); Act 4–6 ≈ kelas 4 (operasi campuran, waktu, keliling-luas, pecahan senilai, KPK/FPB); Act 7–10 ≈ kelas 5 (pecahan campuran/desimal/persen, kecepatan-jarak-waktu, skala, volume, rata-rata, perbandingan). *Ini usulan awal; saya akan sesuaikan jika Anda punya rujukan kurikulum yang dipakai.*
- **Tidak ada "game over" karena salah.** Salah menghasilkan umpan balik lucu + dorongan, bukan hukuman. Petunjuk 3 tingkat dari Bida; setelah petunjuk ke-3 ada penjelasan langkah demi langkah.
- **Terhubung dengan cerita dan peran tim:** Bida membantu membaca soal, Farah memberi alat bantu visual, Nadiya "membidik" jawaban pada soal tertentu. Soal bertema dunia (ramen, shuriken, kristal), bukan soal buku teks biasa.
- **Pembuatan:** ditulis tangan, divalidasi skrip (jawaban dihitung ulang), dan direview Anda per Act.
- **Kertas coretan:** dapat dibuka dari panel soal atau tombol `scratchpad`, tahan mouse/jari untuk menulis.

---

## 8. Risiko dan mitigasi

| # | Risiko | Dampak | Mitigasi |
|---|---|---|---|
| R1 | **Lingkup sangat besar** (10 Act, 4 partner, 10 boss, 20+ puzzle) | Proyek tidak selesai atau kualitas tidak merata | Vertical slice Act 1 dulu; Gerbang review; pipeline berbasis data; potong cakupan opsional (pindah karakter, kontrol sentuh) |
| R2 | **Saya tidak bisa menjalankan Godot .exe dari VM** | Bug tak terlihat, tampilan tidak terverifikasi | Jalur verifikasi di Fase 0: Remote Control di PC Anda atau Godot Linux di VM; smoke test headless; screenshot per milestone |
| R3 | **Build Godot ini versi Mono** dan export template Web belum tentu terpasang | Gagal export web di akhir | Cek di Fase 0; jika perlu pakai Godot standar 4.7.2 hanya untuk export web, instal export template; uji export awal (hello-world) sebelum Fase 6 |
| R4 | **Renderer Forward Plus** di proyek sample, web butuh Compatibility; shader dan partikel bisa berubah | Tampilan web berbeda | Pindah ke Compatibility di Fase 0, uji shader color correction dan partikel |
| R5 | GitHub Pages tidak mengirim header COOP/COEP, sehingga thread web tidak jalan | Game tidak mau mulai | Export **tanpa thread** (didukung Godot 4.3+) |
| R6 | **Ukuran build web** (musik 40 lagu, SFX) | Muat lambat | Hanya aset terpakai disalin, musik OGG ber-bitrate wajar, pemuatan per Act, anggaran ukuran |
| R7 | **Pembaca sprite 16x16** sulit membedakan 4 protagonis dan gender | Karakter terbaca sama | Rancang palet, siluet, dan aksesori khas sejak A1; faceset (lebih besar) membawa identitas; uji Anda di Fase 2 |
| R8 | **Soal matematika salah/tidak sesuai kelas** | Merugikan anak | Validator jawaban, review per Act oleh Anda, rujukan kurikulum yang disepakati |
| R9 | **Partner AI macet atau mengganggu** | Frustrasi | Teleport menyusul, tidak bertabrakan dengan pemain, tidak memblok pintu; uji tiap peta |
| R10 | **Nada terlalu gelap** (Act 6–9, mesin mengamuk) | Melanggar brief | Linter + pass ramah anak; humor tetap hadir; tidak ada kematian eksplisit; pingsan bukan mati |
| R11 | Aset pack kurang untuk boss khusus | Visual boss tampak "pinjaman" | Skala + overlay + efek; jika kurang, saya tampilkan opsi di tiap Gerbang |
| R12 | **Konsistensi cerita** antar Act | Kontradiksi | Story Bible + checklist QA brief per Act; linter nama |
| R13 | Audio web membutuhkan interaksi pengguna | Musik tidak bunyi di awal | Layar judul "klik untuk mulai" |
| R14 | Perubahan Godot 4.7 (versi baru) vs sample 4.3 | Peringatan/deprecation | Smoke test + perbaikan awal di Fase 0 |
| R15 | **Terjemahan Inggris** (humor, kalimat khas, soal matematika) | Humor hilang, soal ambigu, teks meluap | Kunci terjemahan sejak Fase 0, linter dua bahasa, uji tampilan dua bahasa, review Anda per Act |
| R16 | **Rilis bertahap**: save dan cerita harus tetap cocok antar episode | Save lama rusak, kontinuitas pecah | Versi format save + migrasi, Story Bible tetap sumber tunggal, flag cerita bernama stabil |
| R17 | **Sentuh ditunda**: UI dibuat tanpa memikirkan jari | Ulang desain besar di Fase 8b | Aturan dari awal: tombol besar, tanpa hover wajib, input lewat aksi (bukan tombol mentah), kertas coretan berbasis pointer |

---

## 9. Keputusan dan pertanyaan

**Sudah diputuskan (11:04, jawaban Anda)**
1. Bahasa: **Indonesia dan Inggris**; tema edukasi tetap matematika. → bagian 2.7, Fase 0/2/8.
2. Remote Control di PC Anda: **disetujui**. → Fase 0.
3. Input saat pengembangan: keyboard, gamepad, mouse. Virtual joystick dan layar sentuh diadaptasi menjelang rilis. Kertas coretan memakai mouse sekarang, jari nanti. → Fase 5 dan 8b.
4. Aset karakter dari **skrip piksel**, bukan gambar AI. → bagian 4.
5. Rilis **bertahap parsial**. → bagian 5.1.
6. Judul: **"Petualangan Arka di Kampung Ninja"**.

**Asumsi bawaan yang masih berlaku (ubah jika berbeda)**
- Partner AI + perintah sederhana, pindah karakter hanya di momen tertentu.
- Kurikulum matematika: Kurikulum Merdeka umum, kelas 3–5.
- Alur git: satu branch + PR draft per fase di `hilmifuadi/kampung-ninja-inggris`, merge ke `main` setelah Anda setuju.

**Pertanyaan kecil yang tersisa (tidak menghambat Fase 0–1)**
- Pembagian episode 1–4 / 5–7 / 8–10 (bagian 5.1) sudah sesuai, atau Anda ingin potongan lain?
- Judul Inggris: "Arka's Adventure in Ninja Village" cukup, atau ada versi yang Anda inginkan?
- Nama "Desa Daun" dibiarkan tidak diterjemahkan di versi Inggris (agar aman dari kemiripan dengan nama yang dilarang). Setuju?
- Nama folder/repo `kampung-ninja-inggris` mau diganti, atau dibiarkan?

---

## 10. Lampiran

### 10.1 Urutan 5 langkah pertama setelah rencana disetujui
1. Fase 0 (fondasi, renderer Compatibility, jalur uji).
2. Fase 1 (Story Bible + desain Act 1, dua bahasa) → **Gerbang 1**.
3. Fase 2 (Arka, dialog, save).
4. Fase 3 dan 4 dapat dikerjakan bergantian.
5. Fase 5 (matematika) lalu Fase 6 (Act 1) → **Gerbang 2**.

### 10.2 Definisi "Act selesai"
Semua poin checklist brief bagian 9 terpenuhi: nama konsisten, ramah anak, humor alami, tujuan jelas, eksplorasi bermakna, minimal dua (idealnya empat) karakter berkontribusi, hadiah gameplay, petunjuk ke konflik utama, tingkat ancaman sesuai, tak ada konflik kontinuitas, motivasi Kuro dapat dipahami, tema persahabatan/kepemimpinan menguat, **plus**: ≥2 puzzle matematika tervalidasi, smoke test hijau, tersimpan/termuat dengan benar.

### 10.3 Yang sengaja **tidak** dikerjakan sekarang
Deploy GitHub Pages (Fase 9, per episode), kontrol sentuh (Fase 8b, menjelang rilis), ilustrasi cutscene khusus, build Windows, bahasa selain Indonesia dan Inggris.

---

## 11. Status pengerjaan

| Fase | Status |
|---|---|
| 0 Fondasi | File selesai ditulis (renderer Compatibility, input, autoload, struktur, kerangka ID/EN, layar judul, linter, validator, smoke test). **Menunggu verifikasi di Godot** (Remote Control) |
| 1 Story Bible + Act 1 | Dokumen selesai di `docs/` (story_bible, act01_desain, matematika_kurikulum, aset_verifikasi) + data 3 puzzle Act 1. **Menunggu Gerbang 1 (persetujuan Anda)** |
| 2 Inti game | Dikerjakan di branch `fase-2-inti-game` (PR draft): karakter, Arka, interaksi, dialog, audio, peta uji, simpan/muat, UI. Rincian dan yang belum: `docs/fase2_catatan.md`. **Menunggu review** |
| 3 dan seterusnya | Belum dimulai |

Perubahan folder: `kampung-ninja-inggris` diganti menjadi **`arkas-adventure`** (folder dan repo GitHub).
