# Class dasar Patra

Script tersedia di `res://scripts/domain/`. Godot mengenalinya lewat `class_name`
setelah pemindaian filesystem. Class ini tidak perlu ditempel ke node.

| Script | Jenis | Tanggung jawab |
|---|---|---|
| game_enums.gd | RefCounted | Enum kartu, zona, fase, hasil |
| card_definition.gd | Resource | Nama, biaya, stat dasar, kategori kartu |
| card_instance.gd | RefCounted | Kondisi satu kartu selama pertandingan |
| player_state.gd | RefCounted | Arca, Cakra, koleksi kartu dan zona |
| match_state.gd | RefCounted | Dua pemain, ronde, prioritas, Panji, hasil |

## Contoh penggunaan dari script

```gdscript
var definition := CardDefinition.new()
definition.id = "jawara_anoman"
definition.display_name = "Anoman"
definition.card_type = GameEnums.CardType.JAWARA
definition.base_daya = 3 # Angka ilustrasi, bukan balancing final.
definition.max_sukma = 5

var match_state := MatchState.new()
var player := match_state.get_player(0)
var anoman := CardInstance.new(definition, "anoman_001", player.player_id)
player.cards_by_id[anoman.instance_id] = anoman
player.bench_slots[0] = anoman.instance_id
anoman.zone = GameEnums.CardZone.BENCH
anoman.slot_index = 0

anoman.take_damage(2)
print(anoman.current_sukma) # 3
anoman.heal(1)
print(anoman.current_sukma) # 4
```

Contoh ini menunjukkan penyusunan state secara manual. Saat RulesEngine tersedia,
UI mengirim command dan engine memperbarui zona/stat secara konsisten. Jangan
menjadikan contoh ini handler tombol serang: aturan biaya, timing, Warisan, dan
pencegahan lethal belum diterapkan.

## Membuat definisi melalui editor

Pada panel FileSystem: klik kanan → Create New → Resource → CardDefinition.
Simpan sebagai `.tres`, lalu isi property di Inspector. Resource ini dapat menjadi
data contoh; format katalog produksi JSON atau `.tres` belum dikunci. Dua instance
dapat menggunakan definisi sama; HP masing-masing tetap terpisah.

## Menjalankan pemeriksaan

Dengan executable Godot di PATH, dari folder project:

```powershell
godot --headless --editor --import --quit --log-file ./import.log
godot --headless --path . --script res://tests/test_base_classes.gd --log-file ./tests.log
```

Tes memeriksa pemisahan state antar kartu/pemain/match, damage/heal, status Mantra,
reset flag, kapasitas zona, dan lookup ID. Tidak membutuhkan plugin tes tambahan.

Project baru dimulai pada SETUP, ronde 0, Cakra 0, prioritas/Panji -1. Setup system
nanti menentukan ronde pertama dan mengisi kartu. Bench memakai enam slot; zona
tempur bukan zona penyimpanan tambahan. Heal tidak dapat membangkitkan unit mati.

Belum termasuk: modifier Daya, draw/shuffle, combat, efek Lokasi, AI, command/event,
signal UI dan layar pertandingan. `is_finished()` membaca hasil yang sudah diatur
resolver mendatang; method ini tidak otomatis menentukan pemenang dari HP Arca.
