extends Node2D
## Dunia permainan: kamera per ruang, cuaca, HUD, transisi, dan pemuat peta.
## Peta ada di Scenes.MAPS; pemain (Arka) satu instance yang berpindah antar peta.


const PLAYER_SCENE := preload("res://content/characters/arka/arka.tscn")
const NEUTRAL_GRADIENT := preload("res://system/color_correction/gradient_neutral.tres")

var map:Map
var player:Player

@onready var rain: GPUParticles2D = %Rain
@onready var snow: GPUParticles2D = %Snow
@onready var cloud: GPUParticles2D = %Cloud
@onready var leaf: GPUParticles2D = %Leaf
@onready var raylight: GPUParticles2D = %Raylight
@onready var fog: TextureRect = %Fog

@onready var transition: ColorRect = %Transition
@onready var color_correction: ColorRect = %ColorCorrection
@onready var camera_grid: CameraGrid = %CameraGrid
@onready var pivot: Node2D = %Pivot


func _init() -> void:
	add_to_group("world")


func _ready():
	camera_grid.animation_finished.connect(on_camera_animation_finished)
	player = PLAYER_SCENE.instantiate()
	var map_id := GameState.current_map if GameState.current_map != "" else Scenes.START_MAP
	var spawn_id := GameState.current_spawn if GameState.current_spawn != "" else Scenes.START_SPAWN
	var saved_position = GameState.player_position if GameState.restore_position else null
	load_map(map_id,spawn_id,saved_position)
	GameState.restore_position = false


func on_camera_animation_finished():
	pivot.position = camera_grid.global_position


## Ganti peta aktif. saved_position (opsional) menggantikan titik muncul (dipakai saat Lanjutkan).
func load_map(map_id:String, spawn_id := "default", saved_position = null) -> void:
	var path:String = Scenes.MAPS.get(map_id,"")
	if path == "":
		push_error("Peta tidak terdaftar: %s" % map_id)
		return
	if player.get_parent():
		player.get_parent().remove_child(player)
	if map:
		map.queue_free()
		remove_child(map)
	map = load(path).instantiate()
	add_child(map)
	GameState.current_map = map_id
	GameState.current_spawn = spawn_id
	# Posisi diatur sebelum masuk ke pohon agar pintu/pemicu tidak terpicu dari (0,0).
	var entities := map.get_entities_root()
	var spawn := map.find_spawn(spawn_id)
	if saved_position is Vector2:
		player.position = entities.to_local(saved_position)
	elif spawn:
		player.position = spawn.position
		player.facing = spawn.facing
	entities.add_child(player)
	player.sprite.direction = player.facing
	player.velocity = Vector2.ZERO
	camera_grid.target = player
	camera_grid.teleport_to(player.global_position)
	camera_grid.set_world_position(player.global_position)
	pivot.position = camera_grid.global_position
	map.environment_area.environment_changed.connect(apply_environment)
	if map.music != "":
		Audio.play_music(map.music)
	clear_weather()


func clear_weather() -> void:
	rain.emitting = false
	snow.emitting = false
	cloud.emitting = false
	leaf.emitting = false
	raylight.emitting = false
	fog.active = false
	color_correction.gradient = NEUTRAL_GRADIENT


func apply_environment(resource_environment:ResourceEnvironment):
	# METEO
	if !resource_environment:
		return
	rain.emitting = ResourceEnvironment.Meteo.RAIN in resource_environment.meteo_list
	snow.emitting = ResourceEnvironment.Meteo.SNOW in resource_environment.meteo_list
	cloud.emitting = ResourceEnvironment.Meteo.CLOUD in resource_environment.meteo_list
	leaf.emitting = ResourceEnvironment.Meteo.LEAF in resource_environment.meteo_list
	fog.active = ResourceEnvironment.Meteo.FOG in resource_environment.meteo_list
	raylight.emitting = ResourceEnvironment.Meteo.RAY in resource_environment.meteo_list
	# MUSIC
	if resource_environment.music:
		Audio.play_music_stream(resource_environment.music)

	# GRADIENT
	color_correction.gradient = resource_environment.color_gradient
