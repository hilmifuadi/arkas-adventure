# Catatan Fase 2 — Inti game

> Dokumen kerja untuk branch `fase-2-inti-game`: apa yang dibuat, keputusan desain, dan yang belum.
> Diperbarui setiap butir selesai.

## Butir 0 — Rapikan temuan Fase 0

- **`tools/smoke_test.gd`** sekarang keluar dengan kode 1 bila ada skrip/resource yang gagal
  dimuat **atau** Godot mencatat `ERROR` / `SCRIPT ERROR` selama pemeriksaan. Penghitung error
  memakai kelas `Logger` bawaan Godot 4.5+ (`OS.add_logger`), jadi tidak perlu mengurai log.
  Setiap `.tscn` juga di-*instantiate* sekali untuk menangkap skrip/sub-resource yang rusak.
  `GDScript.reload()` sengaja tidak dipakai: ditolak untuk skrip autoload yang sudah punya instance.
  Diuji dengan skrip rusak sengaja (`exit 1`) dan proyek bersih (`exit 0`).
- **`tools/check_all.py`** kini juga menjalankan smoke test bila Godot ditemukan
  (`tools/godot_path.py`: env `GODOT`, build bawaan di folder induk, atau `godot` di PATH).
- **`tools/capture.gd`**: pengambil screenshot sebuah scene (butuh jendela, bukan `--headless`):
  `godot --path . --script tools/capture.gd -- res://main.tscn 30 out.png`.
- **Spasi antarkata judul**: font piksel pack tidak punya lebar untuk karakter spasi, sehingga
  kata menempel. `theme/font_pixel.tres` (`FontVariation`, `spacing_space = 3`) kini menjadi font
  default `theme_1`. Ukuran font harus kelipatan 9 (9, 18, 27, 36) agar piksel tajam.
- **`content/team/neutral_team.tres`** memakai field lama (`team_name`, `enemy_team`) yang sudah
  tidak ada di `ResourceDamageTeam`; diganti ke `team = 0`, `ally_team = Array[int]([])`.
  Error `Cannot assign contents of "Array[Object]" to "Array[int]"` hilang.
- **Warning sub-emitter (diketahui, tidak diperbaiki):** saat `world.tscn` dijalankan di renderer
  Compatibility, Godot memberi dua warning:
  `Sub-emitter modes other than SUB_EMITTER_DISABLED are not supported in the Compatibility renderer`
  dan `The Compatibility renderer does not support particle sub-emitters`.
  Penyebabnya efek **hujan** (`Rain` → `RainOnFloor`) dan **salju** di `world.tscn` yang memakai
  sub-emitter. Dampak: percikan hujan di lantai tidak muncul; hujan dan salju tetap jatuh.
  Peta Act 1 cerah sehingga tidak terpengaruh. Opsi nanti (Fase 8): ganti percikan dengan
  partikel terpisah yang dipicu skrip, atau biarkan.
- Layar judul dipindah ke tata letak "layar virtual 320x180 diskalakan 4x" (pola yang sama dengan
  HUD sample), supaya font 9 px dan tombol tema kayu tampil jelas di 1280x720.

## Butir 1 — Karakter

- `tools/gen_characters.py` (Python + Pillow, deterministik) membuat sprite sheet 64x112 dan faceset 38x38
  untuk **Arka, Bida, Nadiya, Farah, Pak Hilmi, Dokter Zahra** di `assets/generated/characters/<nama>/`.
  Caranya: recolor palet pack (dipisah kepala/badan) + aksesori piksel yang ditempel relatif terhadap
  kepala tiap frame sehingga ikut arah dan animasi jalan. Sumber sprite dicatat di `assets/SOURCES.md`.
- Empat protagonis dibedakan lewat **warna utama dan siluet**: Arka hijau daun + ikat kepala oranye + gagang/sarung
  katana; Bida biru tua + tudung ninja + kacamata bulat + gulungan; Nadiya merah + tudung ninja dengan pita kuning + bandolir;
  Farah kuning + tudung ninja + goggle di dahi + ransel abu dengan antena; Dokter Zahra hijab biru muda + jas putih (lihat pembaruan hijab di bawah). Hasil sheet bisa dilihat dengan
  `python tools/gen_characters.py --preview out.png`.
- Scene tokoh ada di `content/characters/<nama>/<nama>.tscn` (memakai `Character`/`SpriteCharacter` bawaan).
  Ibu Sari memakai `Villager4` dari pack apa adanya (`assets/characters/ibu_sari`).
- **Keputusan:** Bida memakai `NinjaBlue` sesuai arahan, tetapi bentuknya (helm + visor gelap) kurang cocok untuk kacamata;
  kacamata digambar di atas visor. Jika terasa janggal di uji main, alternatifnya `NinjaBlue2`.
- **Belum:** emote per karakter; animasi roll/climb dari `CharacterAnimated/NinjaGreen`.

## Butir 2 — Pemain Arka

- `system/player/player.gd` (`Player extends Character`): mode normal/serang/dash/pingsan.
  Serang katana lewat `Weapon.swing()` (area damage hanya aktif selama ayunan, tiap hitbox kena sekali, katana tersarung
  di sprite saat tidak dipakai); **dash** = ledakan singkat 0,14 dtk, cooldown 0,55 dtk, kebal sesaat, bayangan sisa;
  terluka = knockback + kebal 1 dtk (berkedip). Input memakai action dari `project.godot`.
- **Hati** ada di `GameState.hearts/hearts_max` (sinyal `hearts_changed`). HUD memakai `HeartBar` (satu hati = satu wadah).
- **Pingsan**: hati habis -> jatuh sebentar -> fade -> bangun di rumah Hokage dalam keadaan pulih -> Dokter Zahra menyapa
  (`zahra_bangun`). Tidak ada tulisan atau kata "mati".
- Perbaikan sample: `hitbox.team` kini diisi dari `team` karakter (sebelumnya hitbox musuh bertim netral sehingga
  `DamageArea` musuh melukai dirinya sendiri); setter `Character.actor_scene` aman untuk nilai null.
- **Belum:** *counter* (jendela waktu singkat) yang disebut di rencana bagian 2.5; saya tunda ke Fase 4 bersama AI musuh
  karena butuh aba-aba serangan musuh yang terbaca.

## Butir 3 — Interaksi

- `Interactable` (Area2D, layer fisik 6 "Interact"), `InteractSensor` di depan Arka (memilih target terdekat),
  ikon petunjuk **E** (keyboard) atau **Y** (gamepad) yang berganti otomatis sesuai perangkat terakhir dipakai.
- `DialogTrigger` (mode INTERACT atau ENTER dengan `once_flag`), `Chest` (item sekali, status disimpan sebagai flag
  `chest_<id>`), `NPC` (menoleh ke pemain, bisa bersembunyi dengan "puff").
- Syarat flag `require_flag` / `hide_if_flag` pada tiap Interactable.

## Butir 4 — Dialog

- Autoload `Dialogue`; data di `content/**/dialogs.json` (id dialog -> daftar baris) dan penutur di
  `content/characters/speakers.json`. Fitur: pembicara + faceset, emote, kondisi flag, efek (`set_flag`, `give_item`,
  `heal_all`, `hide_npc`, `objective`, `sfx`, `autosave`), label + `goto`/`end`, pilihan (keyboard, gamepad, mouse/sentuh).
  Format lengkap ada di komentar atas `system/dialogue/dialogue.gd`.
- Kotak dialog memakai `Ui/Dialog/DialogBoxFaceset.png`; efek ketik 45 huruf/dtk dengan **bunyi voice** (nada beda per tokoh
  lewat `pitch`); `interact` melanjutkan, **dash atau tombol "Lewati"** melewati sisa dialog (efek baris yang dilewati tetap
  berjalan; berhenti di pilihan). Klik/ketuk kotak juga melanjutkan.
- Dialog uji (ID + EN): **Dokter Zahra menyembuhkan seluruh tim setiap diajak bicara** (`zahra_sembuhkan`, ada varian
  kunjungan pertama dan berikutnya), **Pak Hilmi** menyapa lalu bersembunyi bila pemain memilih topik ayam
  (`hilmi_sapa`), **S1 pembuka** dari `docs/act01_desain.md` (`act01_s1_pembuka`, otomatis saat masuk halaman), Ibu Sari,
  dan `zahra_bangun`.
- Teks: `content/acts/act01/act01_dialogs.{id,en}.json`, `translations/characters.*.json`, `translations/items.*.json`.

## Butir 5 — Audio

- `default_bus_layout.tres`: bus **Music** dan **SFX** (menggantikan "Sound"); `Settings.apply_volume()` mengaturnya.
- `AudioManager` (`Audio`): crossfade musik, loop manual (OGG pack tidak berulang), kolam 8 pemutar SFX, jingle.
  Musik `calm_village`, `sunny`, `intro` dan 13 SFX disalin dari pack (daftar di `assets/SOURCES.md`). `world.gd` memutar
  musik peta lewat `Map.music` dan `EnvironmentArea`. **Pilihan bunyi belum didengarkan** (uji telinga di Fase 8).

## Butir 6 — Peta dan perpindahan

- `Scenes.change_map(map_id, spawn_id)` dengan fade; registri `Scenes.MAPS`. `SpawnPoint`, `MapDoor`.
  `World.load_map()` memindahkan satu instance Arka antar peta (posisi diatur sebelum masuk pohon agar pintu tidak
  terpicu dari (0,0)).
- Peta uji dibangun `tools/build_maps.gd` (bisa dijalankan ulang; hasilnya `.tscn` biasa yang bisa disunting di editor):
  - `desa_uji`: halaman + rumah Hokage (pintu), jalan tanah, Pak Hilmi, Ibu Sari, peti, pot/peti kayu/rumput yang bisa
    dihancurkan, adegan pembuka; ruang kedua: 3 boneka latih dan 2 musuh sample.
  - `rumah_hokage`: interior dengan Dokter Zahra, titik muncul `door` dan `bed`.
- Musuh sample: `Enemy` (kejar, aba-aba berkedip 0,55 dtk, terjang, cooldown; kalah = berputar pusing lalu "puff" asap).
  Memakai sprite `samurai_blue` dari sample sebagai pengganti sementara (bukan musuh cerita).
- **Keputusan sederhana:** boneka latih = `Destroyable` 3 nyawa dengan sprite buatan skrip (`tools/gen_props.py`); tidak
  respawn. Tileset rumah dari pack bergaya "terbengkalai berlumut" sehingga rumah Hokage terlihat tua; akan diganti saat
  peta Act 1 sungguhan (Fase 6).

## Butir 7 — Simpan/muat dan layar judul

- `SaveSystem`: slot 1 (JSON berversi di `user://saves`). Menyimpan peta, titik muncul, **posisi pemain**, flag,
  inventori, party, hati, dan waktu. **Autosave**: pindah peta, bangun dari pingsan, tombol Simpan, efek dialog `autosave`.
  `Settings` (bahasa, volume, ukuran teks, Mode Santai) disimpan terpisah di `user://settings.cfg`.
- Layar judul: **Mulai** (konfirmasi bila sudah ada simpanan), **Lanjutkan** (nonaktif tanpa simpanan), **Pengaturan**,
  pilihan bahasa.

## Butir 8 — UI

- HUD: hati + teks objektif aktif (`Quests.set_objective`, disimpan di flag `quest_objective`; quest penuh di Fase 6).
- Menu jeda (Esc / Start): Lanjut, Simpan, Pengaturan, Kembali ke judul (`get_tree().paused`).
- Pengaturan: bahasa ID/EN, volume musik dan SFX, ukuran teks (9 px atau 12 px untuk dialog dan objektif), Mode Santai
  (8 hati bukan 5, musuh 1,5x lebih lambat memberi aba-aba dan menyerang).
- Semua UI memakai **layar virtual 320x180 diskalakan 4x** (font 9 px tajam); tombol minimal 18 px virtual (72 px layar),
  tidak ada yang bergantung pada hover, semua bisa dioperasikan dengan keyboard/gamepad/mouse, jadi siap dipindah ke sentuh.
  `PanelContainer` di `theme_1` kini bergaya panel gelap berbingkai oranye (sebelumnya tidak punya gaya).

## Butir 9 — Verifikasi

Semua dijalankan di Godot 4.7.2 (Compatibility) di PC pengguna:

| Pemeriksaan | Cara | Hasil |
|---|---|---|
| Linter brief, validator data, smoke test | `python tools/check_all.py` | lulus (0 error) |
| Gerak, serang, dash, hati, pingsan | `tools/playtest_player.gd` | 12 lulus |
| Interaksi, peti | `tools/playtest_interact.gd` | 6 lulus |
| Dialog, pilihan, lewati, EN | `tools/playtest_dialog.gd` | 11 lulus |
| Audio, bus, crossfade | `tools/playtest_audio.gd` (`--headless`) | 8 lulus |
| Dunia (pintu, boneka, musuh, Zahra, pingsan) | `tools/playtest_world.gd` | 13 lulus |
| **Ujung ke ujung** | `tools/playtest_e2e.gd -- <folder>` | semua lulus |

Alur ujung ke ujung: judul -> Mulai -> berjalan -> bicara Pak Hilmi (pilihan "ayam", objektif berubah) -> terluka oleh musuh ->
pingsan -> bangun di rumah Hokage (pulih + dialog) -> Dokter Zahra menyembuhkan -> jeda -> ganti bahasa ke Inggris -> simpan ->
kembali ke judul -> Lanjutkan -> peta, posisi, hati, flag, inventori, objektif, dan bahasa pulih.

Screenshot ada di `docs/fase2_screenshots/` (`01_judul` ... `15_lanjutkan_pulih`; dibuat `tools/shots_ui.gd` dan `tools/playtest_e2e.gd`).
Catatan: uji ini mengirim input lewat `Input.parse_input_event`, bukan tangan manusia; rasa kontrol, kecepatan, dan keseimbangan
kesulitan perlu dicoba langsung oleh pengguna.

## Yang belum / catatan untuk fase berikutnya

- **Belum dikerjakan (di luar cakupan Fase 2):** partner Bida/Nadiya/Farah, kemampuan tim, boss, puzzle matematika,
  *counter*, shuriken, inventori yang terlihat di UI, kontrol sentuh.
- **Ekspor web (Fase 9):** berkas data `*.json` (dialog, penutur, terjemahan) dibaca lewat `FileAccess`/`DirAccess` dan **tidak
  otomatis ikut ter-export**; tambahkan `*.json` ke filter "Export non-resource files" di preset ekspor. Pemindaian folder
  `res://` dengan `DirAccess` juga tidak andal di build ekspor; saat itu daftar berkas data sebaiknya didaftarkan eksplisit.
- Aset pengganti sementara: musuh `samurai_blue`, Ibu Sari `Villager4`, boneka latih jerami, tileset rumah berlumut.
- `Settings.easy_mode` mengubah `hearts_max` bila dunia sedang berjalan (`GameState.refresh_hearts_max`).
- Sample lama yang tidak dipakai lagi tetapi dibiarkan: `content/map/map_village.tscn`, `system/ui/player_ui.*`,
  `system/behavior/*`, `content/character/*`.
- Warning sub-emitter hujan/salju di Compatibility masih ada (lihat butir 0).

> **Peringatan:** `tools/playtest_e2e.gd` dan `tools/shots_ui.gd` menghapus simpanan slot 1 di `user://` (folder data pengguna Godot untuk proyek ini) agar uji mulai bersih. Jangan jalankan bila ada simpanan yang ingin dipertahankan.

## Pembaruan: hijab dan tudung ninja (keputusan pengguna)

- **Dokter Zahra berhijab** (biru muda lembut + jas putih dengan palang merah); **Bida, Nadiya, Farah bertudung ninja**
  (kain menutup kepala dan leher, jatuh membentuk segitiga kecil di dada, ujung kain berkibar). Arka dan Pak Hilmi tidak berubah.
- `tools/gen_characters.py` diubah: fungsi `neck_cloth()` dan `cloth_tail()` dipakai semua tokoh perempuan di **seluruh arah dan
  baris animasi jalan/serang** (baris lompat dan pose khusus hanya di-recolor); kuncir Bida dan sanggul Nadiya dihapus.
  Ciri khas tiap tokoh dipertahankan: Bida biru tua + kacamata bulat; Nadiya merah + bandolir + pita kuning di sisi tudung;
  Farah kuning + goggle di dahi di atas tudung + ransel antena; Zahra rambut pirang diganti kain hijab biru muda.
- Faceset keempatnya ikut diubah (tepi kain di dahi/leher, pita Nadiya, hijab Zahra). Bagian belakang kepala tetap utuh
  karena kain hanya menimpa piksel yang sudah buram (tidak menambah di luar siluet).
- Dokumen yang diperbarui: `docs/story_bible.md` (3.1 panduan tampilan, 3.2 Dokter Zahra), `docs/RENCANA_PENGERJAAN.md`,
  `assets/SOURCES.md`. `docs/act01_desain.md` tidak menyebut tampilan tokoh sehingga tidak berubah.
- Screenshot sprite: `docs/fase2_screenshots/16_sprite_tokoh.png` (semua tokoh, 4 arah, semua baris animasi, plus faceset).
  Seluruh screenshot dalam game diambil ulang setelah perubahan ini.

## Pembaruan: panggilan "Ayah" dan "Mamah" (keputusan pengguna)

- Arka, Bida, Nadiya, Farah memanggil **Pak Hilmi "Ayah"** dan **Dokter Zahra "Mamah"** (ID). Versi **EN sementara "Dad" / "Mom"**
  (mudah diganti: hanya di `content/acts/act01/act01_dialogs.en.json`, kunci `CH_HILMI_*`, `DLG_HILMI_ARKA_*`, `DLG_ZAHRA_ARKA_RAMEN`,
  `DLG_ZAHRA_TERIMA_KASIH`). Warga lain dan narasi tetap "Hokage Pak Hilmi" / "Dokter Zahra"; **nama pembicara tidak berubah**
  (`translations/characters.*.json`), hanya kata sapaan dalam kalimat.
- Dialog uji yang diubah: pilihan dan jawaban Arka di `hilmi_sapa` ("Ayah, di depan ada ayam!", "Ayah, ada ramen gratis?"),
  `zahra_sembuhkan` ("Siap, Mamah!" dan baris baru "Terima kasih, Mamah!"). Pak Hilmi tidak lagi menyebut dirinya "Bapak"
  (kalimatnya dibuat netral) supaya tidak memutuskan hubungan keluarga yang belum ditentukan.
- `docs/story_bible.md` 3.2: catatan panggilan + tiga opsi hubungan ditandai **[USULAN]** (anak kandung / anak asuh / murid yang
  dianggap anak), tidak diputuskan; keselarasan dengan tema Arka dan hubungan Pak Hilmi-Kuro dicatat. `docs/act01_desain.md`:
  baris Arka di S2 dan S6 ditambahkan, serta catatan panggilan di bagian 12.3.

## Pembaruan: hubungan keluarga = anak kandung (keputusan pengguna)

- Pengguna memutuskan **anak kandung**. Tafsir yang dipakai (bisa dikoreksi): **Arka, Bida, Nadiya, Farah adalah anak kandung Pak Hilmi
  dan Dokter Zahra, jadi bersaudara dan rekan tim**; usia/urutan lahir belum ditentukan. Ini **perubahan dari brief** (brief menyebut
  "tiga teman perempuan"). Dicatat di `docs/story_bible.md` 2.1 dan 3.2 (tiga opsi [USULAN] lama diganti keputusan + dampak:
  Arka bercita-cita seperti ayahnya, Pak Hilmi tidak memberi keistimewaan, tim = keluarga, Kuro melihat Arka sebagai "anak sang guru"
  di Act 8 tanpa mengubah motivasinya), `docs/act01_desain.md` (S2 dan catatan 12.3), `docs/RENCANA_PENGERJAAN.md` (keputusan 7-8), `README.md`.
- Dialog uji: Pak Hilmi dan Dokter Zahra kini boleh menyebut diri "Ayah"/"Mamah"; gurauan ringan baru: "Ramen gratis itu urusan Hokage.
  Dan Hokage tidak pilih kasih, termasuk pada anak sendiri." (ID/EN), serta Zahra: "Mamah catat resepnya." Dialog antar-saudara tidak diubah.
  Di S2 (desain): Pak Hilmi "tidak ada jalur khusus untuk anak Hokage" dan balasan Arka.

## Pembaruan: HUD objektif ringkas

- Objektif kini **satu baris kecil** (font 18 px layar = setengah ukuran sebelumnya, tetap kelipatan 9 agar font piksel tajam; 27 px bila
  ukuran teks Besar), **lebar menyesuaikan teks**, latar semi-transparan (60%), rapat di bawah baris hati kiri atas, **lebar maksimum
  40% layar** (teks panjang EN dibungkus). Lapisan terpisah dari hati (tanpa skala 4x).
- Perilaku: tampil penuh saat objektif berubah, memudar ke 25% setelah 4 detik; **tahan tombol `objective`** (O / Back gamepad) untuk
  menampilkannya penuh lagi. Tidak bentrok dengan kotak dialog (di bawah) maupun tombol Lewati (kanan atas).
- Input baru `objective` di `project.godot`. **Back (gamepad) sebelumnya dipakai `scratchpad`; saya pindahkan kertas coretan ke R3**
  (tekan stik kanan) karena fitur itu baru dibangun di Fase 5. Keyboard `scratchpad` tetap Tab. README diperbarui.
- Diuji `tools/playtest_hud.gd` (8 pemeriksaan); screenshot `20_hud_objektif_id`, `21_hud_objektif_pudar`, `22_hud_objektif_en`.

## Pembaruan: akar masalah "pohon tidak sempurna" setelah pot/peti hancur

- **Akar masalah (di `tools/build_maps.gd`, bukan di Destroyable):** pot dan peti diletakkan sebagai *scene tile* pada lapisan `Wall`,
  di petak yang **sama dengan petak pohon**. `TileMap.set_cell` menimpa petak itu, jadi pohon kehilangan petak bawahnya; ketika pot
  hancur, bagian pohon yang tertimpa tetap hilang (terlihat sebagai pohon bertakik). Masalah kedua dari penyebab serupa: blok pohon
  lebar 4 petak diletakkan dengan **jarak 3 petak**, sehingga pohon yang berdampingan saling memotong (garis potong vertikal di tepi
  pohon); beberapa pohon juga melewati tepi layar/batas ruang kamera.
- **Perbaikan:** pohon berjarak minimal 4 petak, tidak melintasi batas ruang kamera (x 10|11) maupun tepi layar (pohon bawah dipindah
  ke y=3..5 dan jalan tanah naik ke y=1..2); pot/peti dipindah ke petak kosong. `build_maps.gd` kini **mencatat petak lapisan Wall
  (`claim`) dan gagal (exit 1) bila ada objek menimpa objek lain**, sehingga masalah ini tidak terulang. Peta di-build ulang: 0 tumpang tindih.
- Screenshot sebelum/sesudah: `17_pot_pohon_LAMA_sebelum/sesudah.png` dan `18_pot_pohon_BARU_sebelum/sesudah.png`
  (dibuat `tools/shots_destroy.gd`). Peta sample bawaan `map_village.tscn` tidak dipakai lagi dan tidak diubah.
