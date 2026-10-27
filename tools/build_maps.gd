extends SceneTree
## Membangun peta uji Fase 2 sebagai scene (.tscn) dari tileset proyek, secara deterministik:
##   godot --headless --path . --script tools/build_maps.gd
## Hasil: content/acts/act01/map_desa_uji.tscn dan map_rumah_hokage.tscn.
## Peta bisa dibuka dan disunting di editor Godot setelah dibangun; skrip ini hanya titik awal.
##
## Koordinat: satu ruang kamera = 20x11 petak. Ruang (0,0) mencakup petak x -9..10, y -5..5;
## ruang (1,0) mencakup x 11..30. Posisi dunia petak (tx,ty) = (16+16*tx, 16+16*ty).


const MAP_SCENE := "res://system/map/map.tscn"
const OUT_DIR := "res://content/acts/act01/"
const TILE := 16

# Sumber di content/map/tileset.tres
const SRC_VILLAGE := 0
const SRC_FLOOR := 1
const SRC_INTERIOR := 2
const SRC_WALL := 4
const SRC_SCENES := 5
const SCENE_CRATE := 1
const SCENE_GRASS := 2
const SCENE_POT := 3

# Lapisan TileMap (lihat system/map/map.tscn)
const L_WALL := 0
const L_WALL2 := 1
const L_DETAIL := 2
const L_FLOOR := 3

const GRASS_VARIANTS := [
	[Vector2i(0,12),70], [Vector2i(1,12),6], [Vector2i(2,12),6], [Vector2i(3,12),6],
	[Vector2i(4,12),4], [Vector2i(2,11),4], [Vector2i(3,11),4],
]

var map_root:Node2D  # akar peta (skrip Map; properti lewat set() karena skrip butuh autoload)
var tilemap:TileMap
var tileset:TileSet
var rng := RandomNumberGenerator.new()
## Petak lapisan Wall yang sudah terisi (petak -> label). Dipakai agar blok pohon/rumah dan benda
## (pot, peti, rumput: scene tile) tidak saling menimpa; penimpaan membuat pohon tampak terpotong.
var claimed := {}
var conflicts := 0


func _initialize() -> void:
	rng.seed = 12345
	tileset = load("res://content/map/tileset.tres")
	build_outdoor()
	build_interior()
	print("build_maps: selesai, %d tumpang tindih" % conflicts)
	quit(1 if conflicts > 0 else 0)


# ------------------------------------------------------------------ bantuan

func new_map(map_id:String, node_name:String, music:String, title_key:String) -> void:
	map_root = load(MAP_SCENE).instantiate()
	map_root.name = node_name
	map_root.set("map_id",map_id)
	map_root.set("music",music)
	map_root.set("title_key",title_key)
	claimed.clear()
	tilemap = map_root.get_node("Tilemap")


func save_map(file_name:String) -> void:
	var packed := PackedScene.new()
	var error := packed.pack(map_root)
	if error != OK:
		push_error("Gagal pack %s: %d" % [file_name,error])
		return
	ResourceSaver.save(packed,OUT_DIR+file_name)
	print("disimpan: ", OUT_DIR+file_name)
	map_root.free()


func add_owned(parent:Node, node:Node, node_name := "") -> Node:
	if node_name != "":
		node.name = node_name
	parent.add_child(node)
	node.owner = map_root
	return node


func world_pos(tx:float, ty:float) -> Vector2:
	# Posisi lokal di dalam Tilemap (Tilemap sendiri berada di (8,8) pada map.tscn).
	return Vector2(tx*TILE+TILE/2.0,ty*TILE+TILE/2.0)


func pick_grass() -> Vector2i:
	var total := 0
	for entry in GRASS_VARIANTS:
		total += entry[1]
	var roll := rng.randi_range(0,total-1)
	for entry in GRASS_VARIANTS:
		roll -= entry[1]
		if roll < 0:
			return entry[0]
	return Vector2i(0,12)


func fill_grass(x0:int, y0:int, x1:int, y1:int) -> void:
	for x in range(x0,x1+1):
		for y in range(y0,y1+1):
			tilemap.set_cell(L_FLOOR,Vector2i(x,y),SRC_FLOOR,pick_grass())


## Catat petak lapisan Wall; kembalikan false (dan hitung konflik) bila petak sudah dipakai objek lain.
func claim(layer:int, cell:Vector2i, label:String) -> bool:
	if layer != L_WALL:
		return true
	if claimed.has(cell):
		push_error("Tumpang tindih di petak %s: %s menimpa %s" % [cell,label,claimed[cell]])
		conflicts += 1
		return false
	claimed[cell] = label
	return true


## Salin blok atlas (hanya petak yang ada) ke peta mulai dari petak "at".
func stamp(layer:int, source_id:int, atlas_origin:Vector2i, size:Vector2i, at:Vector2i, label := "blok") -> void:
	var source:TileSetAtlasSource = tileset.get_source(source_id)
	for dx in size.x:
		for dy in size.y:
			var atlas := atlas_origin+Vector2i(dx,dy)
			if source.has_tile(atlas) and claim(layer,at+Vector2i(dx,dy),"%s@%s" % [label,at]):
				tilemap.set_cell(layer,at+Vector2i(dx,dy),source_id,atlas)


func tree(x:int, y:int) -> void:
	stamp(L_WALL,SRC_VILLAGE,Vector2i(0,6),Vector2i(4,3),Vector2i(x,y),"pohon")


func scene_tile(scene_id:int, tx:int, ty:int) -> void:
	if claim(L_WALL,Vector2i(tx,ty),"benda%d" % scene_id):
		tilemap.set_cell(L_WALL,Vector2i(tx,ty),SRC_SCENES,Vector2i.ZERO,scene_id)


func add_wall_rect(rect_name:String, tile_rect:Rect2i) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = world_pos(tile_rect.position.x,tile_rect.position.y)-Vector2(TILE/2.0,TILE/2.0)+Vector2(tile_rect.size*TILE)/2.0
	add_owned(tilemap,body,rect_name)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(tile_rect.size*TILE)
	shape.shape = rectangle
	add_owned(body,shape,"Shape")


func add_spawn(spawn_id:String, tx:float, ty:float, facing := Vector2.DOWN) -> void:
	var point:Marker2D = load("res://system/map/spawn_point.gd").new()
	point.set("spawn_id",spawn_id)
	point.set("facing",facing)
	point.position = world_pos(tx,ty)
	add_owned(tilemap,point,"Spawn_"+spawn_id)


func add_door(door_name:String, target_map:String, target_spawn:String, tile_rect:Rect2i) -> void:
	var door:Area2D = load("res://system/map/map_door.gd").new()
	door.set("target_map",target_map)
	door.set("target_spawn",target_spawn)
	door.position = world_pos(tile_rect.position.x,tile_rect.position.y)-Vector2(TILE/2.0,TILE/2.0)+Vector2(tile_rect.size*TILE)/2.0
	add_owned(tilemap,door,door_name)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(tile_rect.size*TILE)
	shape.shape = rectangle
	add_owned(door,shape,"Shape")


func add_instance(scene_path:String, inst_name:String, tx:float, ty:float, props := {}) -> Node:
	var inst:Node2D = load(scene_path).instantiate()
	inst.name = inst_name
	inst.position = world_pos(tx,ty)
	for key in props:
		inst.set(key,props[key])
	add_owned(tilemap,inst)
	return inst


func add_dialog_zone(zone_name:String, dialog_id:String, once_flag:String, tile_rect:Rect2i) -> void:
	var trigger:Area2D = load("res://system/interact/dialog_trigger.gd").new()
	trigger.set("dialog_id",dialog_id)
	trigger.set("mode",1)  # DialogTrigger.Mode.ENTER
	trigger.set("once_flag",once_flag)
	trigger.position = world_pos(tile_rect.position.x,tile_rect.position.y)-Vector2(TILE/2.0,TILE/2.0)+Vector2(tile_rect.size*TILE)/2.0
	add_owned(tilemap,trigger,zone_name)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(tile_rect.size*TILE)
	shape.shape = rectangle
	add_owned(trigger,shape,"Shape")


# ------------------------------------------------------------------ peta luar

func build_outdoor() -> void:
	new_map("desa_uji","MapDesaUji","village","MAP_DESA_UJI")
	fill_grass(-10,-6,31,6)
	# jalan tanah: dari pintu rumah turun lalu ke timur melewati ruang kedua
	var path_cells:Array[Vector2i] = []
	for y in range(0,2):
		path_cells.append(Vector2i(-1,y))
		path_cells.append(Vector2i(0,y))
	for x in range(-1,31):
		path_cells.append(Vector2i(x,1))
		path_cells.append(Vector2i(x,2))
	tilemap.set_cells_terrain_connect(L_FLOOR,path_cells,0,1)
	# rumah Hokage (blok rumah atap miring dari tileset desa)
	stamp(L_WALL,SRC_VILLAGE,Vector2i(12,6),Vector2i(4,5),Vector2i(-2,-5),"rumah")
	# pepohonan di tepi
	# Blok pohon berlebar 4 petak: jarak antar-pohon >= 4, tidak melintasi batas ruang kamera (x 10|11)
	# dan tidak keluar dari layar (pohon utuh).
	for x in [-9,2,6,11,15,19,23,27]:
		tree(x,-5)
	for x in [-9,-5,-1,3,7,11,15,19,23,27]:
		tree(x,3)
	tree(-9,-1)
	# benda yang bisa dihancurkan di halaman
	scene_tile(SCENE_POT,3,-2)
	scene_tile(SCENE_POT,4,-2)
	scene_tile(SCENE_CRATE,7,-2)
	scene_tile(SCENE_GRASS,-5,1)
	scene_tile(SCENE_GRASS,-4,1)
	scene_tile(SCENE_GRASS,8,0)
	# batas tak terlihat agar pemain tidak keluar peta
	add_wall_rect("BatasAtas",Rect2i(-11,-7,44,2))
	add_wall_rect("BatasBawah",Rect2i(-11,6,44,2))
	add_wall_rect("BatasKiri",Rect2i(-11,-7,2,15))
	add_wall_rect("BatasKanan",Rect2i(31,-7,2,15))
	# titik muncul
	add_spawn("start",-1,1)
	add_spawn("hokage_door",-1,0.6)
	add_spawn("default",-1,1)
	# pintu ke rumah Hokage (di bawah pintu rumah)
	add_door("PintuRumahHokage","rumah_hokage","door",Rect2i(-2,-1,2,1))
	# penghuni desa
	add_instance("res://content/characters/pak_hilmi/pak_hilmi.tscn","PakHilmi",-4,-1)
	add_instance("res://content/characters/ibu_sari/ibu_sari.tscn","IbuSari",4,-1)
	# peti perlengkapan
	add_instance("res://system/interact/chest.tscn","PetiPerlengkapan",7,-4,{"chest_id":"desa_uji_1","item":"shuriken_latihan","count":5})
	# adegan pembuka (S1) saat pertama kali mulai
	add_dialog_zone("PemicuPembuka","act01_s1_pembuka","act01_start_seen",Rect2i(-3,0,4,3))
	# ruang kedua: latihan dan musuh
	add_instance("res://content/destroyable/training_dummy.tscn","BonekaLatih1",15,-2)
	add_instance("res://content/destroyable/training_dummy.tscn","BonekaLatih2",17,-2)
	add_instance("res://content/destroyable/training_dummy.tscn","BonekaLatih3",19,-2)
	add_instance("res://content/enemies/samurai_latihan/samurai_latihan.tscn","SamuraiLatihan1",25,0)
	add_instance("res://content/enemies/samurai_latihan/samurai_latihan.tscn","SamuraiLatihan2",27,-2)
	scene_tile(SCENE_POT,13,0)
	scene_tile(SCENE_CRATE,22,-2)
	save_map("map_desa_uji.tscn")


# ------------------------------------------------------------------ rumah Hokage (interior)

func build_interior() -> void:
	new_map("rumah_hokage","MapRumahHokage","sunny","MAP_RUMAH_HOKAGE")
	# latar gelap di luar ruangan
	var void_rect := ColorRect.new()
	void_rect.color = Color(0.0784314,0.105882,0.105882,1)
	void_rect.position = Vector2(-300,-200)
	void_rect.size = Vector2(700,400)
	void_rect.z_index = -20
	add_owned(map_root,void_rect,"Latar")
	var x0 := -6
	var x1 := 5
	var y0 := -4
	var y1 := 3
	for x in range(x0+1,x1):
		for y in range(y0+1,y1):
			tilemap.set_cell(L_FLOOR,Vector2i(x,y),SRC_INTERIOR,Vector2i(1,1))
	# bingkai dinding (wall_simple)
	tilemap.set_cell(L_WALL,Vector2i(x0,y0),SRC_WALL,Vector2i(0,0))
	tilemap.set_cell(L_WALL,Vector2i(x1,y0),SRC_WALL,Vector2i(4,0))
	tilemap.set_cell(L_WALL,Vector2i(x0,y1),SRC_WALL,Vector2i(0,4))
	tilemap.set_cell(L_WALL,Vector2i(x1,y1),SRC_WALL,Vector2i(4,4))
	for x in range(x0+1,x1):
		tilemap.set_cell(L_WALL,Vector2i(x,y0),SRC_WALL,Vector2i(1 if x%2 == 0 else 2,0))
		if x != -1 and x != 0:  # celah pintu di bawah
			tilemap.set_cell(L_WALL,Vector2i(x,y1),SRC_WALL,Vector2i(1 if x%2 == 0 else 2,4))
	for y in range(y0+1,y1):
		tilemap.set_cell(L_WALL,Vector2i(x0,y),SRC_WALL,Vector2i(0,1+(y%3+3)%3))
		tilemap.set_cell(L_WALL,Vector2i(x1,y),SRC_WALL,Vector2i(4,1+(y%3+3)%3))
	# tabrakan dinding
	add_wall_rect("DindingAtas",Rect2i(x0,y0-1,x1-x0+1,2))
	add_wall_rect("DindingKiri",Rect2i(x0-1,y0,2,y1-y0+1))
	add_wall_rect("DindingKanan",Rect2i(x1,y0,2,y1-y0+1))
	add_wall_rect("DindingBawahKiri",Rect2i(x0,y1,x1-x0-5,1))
	add_wall_rect("DindingBawahKanan",Rect2i(1,y1,x1,1))
	add_wall_rect("BatasBawah",Rect2i(x0,y1+2,x1-x0+1,1))
	add_spawn("door",-0.5,2)
	add_spawn("bed",-3,0)
	add_spawn("default",-0.5,2)
	add_door("PintuKeluar","desa_uji","hokage_door",Rect2i(-1,y1+1,2,1))
	add_instance("res://content/characters/dokter_zahra/dokter_zahra.tscn","DokterZahra",2,-2)
	scene_tile(SCENE_POT,-5,-3)
	scene_tile(SCENE_POT,4,-3)
	scene_tile(SCENE_CRATE,-5,2)
	save_map("map_rumah_hokage.tscn")
