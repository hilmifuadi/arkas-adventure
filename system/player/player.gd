extends Character
class_name Player
## Arka, tokoh yang dikendalikan pemain: gerak, serang katana, dash, hati, pingsan, interaksi.
## Kalah = pingsan (tanpa kekerasan): layar memudar, bangun di rumah Hokage dalam keadaan pulih.


signal fainted
signal attacked
signal dashed

enum Mode {NORMAL,ATTACK,DASH,FAINT}

const PLAYER_LAYER := 5

@export_category("combat")
@export var attack_time := 0.28
@export var attack_lunge := 70.0
@export var dash_speed := 280.0
@export var dash_time := 0.14
@export var dash_cooldown := 0.55
@export var invulnerable_time := 1.0
@export var weapon_resource:ResourceWeapon

## True saat dialog, menu, atau transisi: pemain tidak membaca input.
var locked := false
var mode:Mode = Mode.NORMAL
var facing := Vector2.DOWN
var invulnerable := false
var knockback := Vector2.ZERO
var dash_remaining := 0.0
var dash_cooldown_left := 0.0
var ghost_timer := 0.0

@onready var weapon: Weapon = $Weapon
@onready var hitbox: Hitbox = $Hitbox
@onready var sensor = get_node_or_null("InteractSensor")


func _ready() -> void:
	add_to_group("player")
	set_collision_layer_value(PLAYER_LAYER,true)
	hitbox.damage_received.connect(on_damage_received)
	weapon.team = team
	weapon.resource_weapon = weapon_resource
	weapon.direction = facing
	sprite.direction = facing


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	dash_cooldown_left = maxf(dash_cooldown_left-delta,0.0)
	match mode:
		Mode.NORMAL:
			process_normal(delta)
		Mode.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO,deceleration*delta)
		Mode.DASH:
			process_dash(delta)
		Mode.FAINT:
			velocity = velocity.move_toward(Vector2.ZERO,deceleration*delta)
	if knockback.length() > 1.0:
		velocity += knockback
		knockback = knockback.move_toward(Vector2.ZERO,900*delta)
	move_and_slide()


func _process(_delta: float) -> void:
	if invulnerable and mode != Mode.FAINT:
		sprite.modulate.a = 0.35 if (Time.get_ticks_msec()/70)%2 == 0 else 1.0
	elif sprite.modulate.a != 1.0:
		sprite.modulate.a = 1.0


func process_normal(delta:float) -> void:
	var input_vector := Vector2.ZERO
	if !locked:
		input_vector = Input.get_vector("move_left","move_right","move_up","move_down")
	move_vector = input_vector
	if input_vector.length():
		facing = snap_direction(input_vector)
		sprite.anim = SpriteCharacter.Anim.MOVING
		velocity = velocity.move_toward(input_vector*speed,acceleration*delta)
	else:
		sprite.anim = SpriteCharacter.Anim.IDLE
		velocity = velocity.move_toward(Vector2.ZERO,deceleration*delta)
	if locked:
		return
	if Input.is_action_just_pressed("attack"):
		start_attack()
	elif Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
		start_dash(input_vector)
	elif Input.is_action_just_pressed("interact") and sensor and !Dialogue.is_busy():
		sensor.interact()


func snap_direction(vector:Vector2) -> Vector2:
	if absf(vector.x) > absf(vector.y):
		return Vector2(signf(vector.x),0)
	return Vector2(0,signf(vector.y))


func start_attack() -> void:
	mode = Mode.ATTACK
	sprite.direction = facing
	sprite.anim = SpriteCharacter.Anim.ATTACK
	velocity = facing*attack_lunge
	weapon.swing(facing,attack_time*0.6)
	Audio.play_sfx("slash")
	attacked.emit()
	await get_tree().create_timer(attack_time,false).timeout
	if mode == Mode.ATTACK:
		mode = Mode.NORMAL


func start_dash(input_vector:Vector2) -> void:
	var dash_direction := input_vector.normalized() if input_vector.length() else facing
	mode = Mode.DASH
	dash_remaining = dash_time
	dash_cooldown_left = dash_cooldown
	velocity = dash_direction*dash_speed
	sprite.direction = facing
	sprite.anim = SpriteCharacter.Anim.JUMP
	set_invulnerable(dash_time+0.15)
	Audio.play_sfx("dash")
	dashed.emit()


func process_dash(delta:float) -> void:
	dash_remaining -= delta
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		ghost_timer = 0.035
		spawn_ghost()
	if dash_remaining <= 0.0:
		velocity = velocity.limit_length(speed)
		mode = Mode.NORMAL


func spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame_coords = sprite.frame_coords
	ghost.offset = sprite.offset
	ghost.global_position = sprite.global_position
	ghost.modulate = Color(1,1,1,0.5)
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost,"modulate:a",0.0,0.18)
	tween.tween_callback(ghost.queue_free)


func set_invulnerable(time:float) -> void:
	invulnerable = true
	await get_tree().create_timer(time,false).timeout
	if mode != Mode.FAINT:
		invulnerable = false


func on_damage_received(damage:ResourceDamage,from_pos:Vector2) -> void:
	if invulnerable or mode == Mode.FAINT:
		return
	GameState.damage_hearts(damage.amount)
	knockback = from_pos.direction_to(global_position)*maxf(float(damage.push_force),160.0)
	Audio.play_sfx("hurt")
	flash_white()
	if GameState.hearts <= 0:
		faint()
	else:
		set_invulnerable(invulnerable_time)


func flash_white() -> void:
	sprite.modulate = Color(4,4,4)
	await get_tree().create_timer(0.12,false).timeout
	sprite.modulate = Color.WHITE


## Pingsan: jatuh sebentar, lalu Scenes memudarkan layar dan membangunkan Arka di rumah Hokage.
func faint() -> void:
	mode = Mode.FAINT
	invulnerable = true
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.anim = SpriteCharacter.Anim.DEAD
	fainted.emit()
	await get_tree().create_timer(0.9,false).timeout
	Scenes.recover_from_faint()


## Dipanggil setelah bangun: Arka kembali berdiri dan bisa digerakkan.
func wake_up() -> void:
	mode = Mode.NORMAL
	invulnerable = false
	knockback = Vector2.ZERO
	velocity = Vector2.ZERO
	sprite.anim = SpriteCharacter.Anim.IDLE
	facing = Vector2.DOWN
	sprite.direction = facing
