extends Character
class_name Enemy
## Musuh dasar: diam, mengejar pemain bila dekat, memberi aba-aba (berkedip), lalu menerjang.
## Kalah = "puff" asap (tanpa kekerasan). AI lebih lengkap (kelompok, makanan) ada di Fase 4.


signal defeated

enum Mode {IDLE,CHASE,TELEGRAPH,ATTACK,COOLDOWN,STUNNED,DEFEATED}

@export_category("enemy")
@export var life_max := 3
@export var chase_speed := 55.0
@export var notice_radius := 90.0
@export var lose_radius := 150.0
@export var attack_range := 22.0
@export var telegraph_time := 0.55
@export var attack_time := 0.25
@export var lunge_speed := 170.0
@export var cooldown_time := 1.5
@export var stun_time := 0.35
@export var contact_damage:ResourceDamage

var life := 0
var mode:Mode = Mode.IDLE
var target:Node2D
var timer := 0.0
var attack_direction := Vector2.DOWN
var knockback := Vector2.ZERO

@onready var hitbox: Hitbox = $Hitbox
var damage_area:DamageArea


func _ready() -> void:
	life = life_max
	add_to_group("enemy")
	hitbox.team = team
	hitbox.damage_received.connect(on_damage_received)
	damage_area = DamageArea.new()
	damage_area.damage = contact_damage
	damage_area.team = team
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	shape.shape = circle
	damage_area.add_child(shape)
	damage_area.position = Vector2(0,-3)
	add_child(damage_area)
	damage_area.monitoring = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or mode == Mode.DEFEATED:
		return
	find_target()
	timer -= delta
	var wanted := Vector2.ZERO
	match mode:
		Mode.IDLE:
			sprite.anim = SpriteCharacter.Anim.IDLE
			if target and distance_to_target() < notice_radius:
				mode = Mode.CHASE
		Mode.CHASE:
			if !target or distance_to_target() > lose_radius:
				mode = Mode.IDLE
			elif distance_to_target() <= attack_range:
				start_telegraph()
			else:
				wanted = global_position.direction_to(target.global_position)
				sprite.anim = SpriteCharacter.Anim.MOVING
				sprite.direction = wanted
		Mode.TELEGRAPH:
			sprite.anim = SpriteCharacter.Anim.IDLE
			sprite.modulate = Color(2.0,1.6,1.6) if int(timer*16.0)%2 == 0 else Color.WHITE
			if timer <= 0.0:
				start_attack()
		Mode.ATTACK:
			wanted = attack_direction*(lunge_speed/chase_speed)
			if timer <= 0.0:
				end_attack()
		Mode.COOLDOWN:
			sprite.anim = SpriteCharacter.Anim.IDLE
			if timer <= 0.0:
				mode = Mode.CHASE
		Mode.STUNNED:
			sprite.anim = SpriteCharacter.Anim.IDLE
			if timer <= 0.0:
				mode = Mode.CHASE
	velocity = velocity.move_toward(wanted*chase_speed,acceleration*delta)
	if knockback.length() > 1.0:
		velocity += knockback
		knockback = knockback.move_toward(Vector2.ZERO,900*delta)
	move_and_slide()


func find_target() -> void:
	if is_instance_valid(target):
		return
	target = get_tree().get_first_node_in_group("player")


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


func easy_factor() -> float:
	return 1.5 if Settings.easy_mode else 1.0


func start_telegraph() -> void:
	mode = Mode.TELEGRAPH
	timer = telegraph_time*easy_factor()
	attack_direction = global_position.direction_to(target.global_position)
	sprite.direction = attack_direction


func start_attack() -> void:
	mode = Mode.ATTACK
	timer = attack_time
	sprite.modulate = Color.WHITE
	sprite.anim = SpriteCharacter.Anim.ATTACK
	damage_area.set_deferred("monitoring",true)


func end_attack() -> void:
	damage_area.set_deferred("monitoring",false)
	mode = Mode.COOLDOWN
	timer = cooldown_time*easy_factor()


func on_damage_received(damage:ResourceDamage, from_pos:Vector2) -> void:
	if mode == Mode.DEFEATED:
		return
	life -= damage.amount
	knockback = from_pos.direction_to(global_position)*maxf(float(damage.push_force),100.0)
	Audio.play_sfx("enemy_hit")
	sprite.modulate = Color(4,4,4)
	damage_area.set_deferred("monitoring",false)
	if life <= 0:
		defeat()
		return
	mode = Mode.STUNNED
	timer = stun_time
	await get_tree().create_timer(0.12,false).timeout
	if mode != Mode.DEFEATED:
		sprite.modulate = Color.WHITE


## Kalah: berputar pusing sebentar, lalu hilang bersama kepulan asap.
func defeat() -> void:
	mode = Mode.DEFEATED
	velocity = Vector2.ZERO
	damage_area.set_deferred("monitoring",false)
	set_deferred("collision_layer",0)
	hitbox.set_deferred("monitorable",false)
	sprite.modulate = Color.WHITE
	defeated.emit()
	var tween := create_tween()
	for i in 6:
		tween.tween_callback(func(): sprite.direction = Vector2.from_angle(i*PI/2.0)).set_delay(0.06)
	await tween.finished
	Audio.play_sfx("puff")
	Puff.spawn(get_parent(),global_position+Vector2(0,-6))
	queue_free()
