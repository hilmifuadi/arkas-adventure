@icon("../weapon/icon_weapon.png")
@tool
extends Node2D
class_name Weapon


enum State {BACK,ATTACK,PROJECTED,ON_FLOOR}

## Busur ayunan (radian) di kiri-kanan arah serang.
const SWING_ARC := 1.2

@export var resource_weapon:ResourceWeapon:
	set(v):
		resource_weapon = v
		if !is_inside_tree():
			await ready
		if !resource_weapon:
			sprite.texture = null
			damage_area.damage = null
			return
		sprite.texture = resource_weapon.sprite_in_hand
		damage_area.damage = resource_weapon.damage
		update_weapon()
@export var team:ResourceDamageTeam:
	set(v):
		team = v
		if !is_inside_tree():
			await ready
		damage_area.team = team
## Senjata disembunyikan saat tidak dipakai (mis. katana yang tersarung di punggung sprite).
@export var hide_when_idle := false

var direction:= Vector2.ZERO:
	set(v):
		direction = v
		update_weapon()

var state:State = State.BACK:
	set(v):
		state = v
		update_weapon()

var swing_tween:Tween

@onready var sprite: Sprite2D = $Sprite
@onready var damage_area: DamageArea = $Sprite/DamageArea


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	damage_area.monitoring = false
	update_weapon()


func update_weapon():
	if !resource_weapon:
		return
	match state:
		State.BACK:
			sprite.visible = !hide_when_idle
			sprite.texture = resource_weapon.sprite_in_hand
			sprite.offset = Vector2.ZERO
			show_behind_parent = direction.y < 0
			sprite.position = Vector2(10,10)*direction
			sprite.rotation = direction.angle()-(PI/2)
		State.ATTACK:
			sprite.visible = true
			sprite.texture = resource_weapon.sprite
			show_behind_parent = direction.y < 0
		_:
			sprite.rotation = 0
			sprite.texture = resource_weapon.sprite
			sprite.offset = Vector2(-7,-5)*direction
			show_behind_parent = direction.y >= 0


## Ayunan senjata ke arah dir. Area damage aktif selama ayunan; tiap hitbox hanya kena sekali.
func swing(dir:Vector2, duration := 0.16):
	if !resource_weapon:
		return
	direction = dir.normalized()
	state = State.ATTACK
	var base_angle := direction.angle()+(PI/2)
	sprite.position = direction*4
	sprite.offset = Vector2(0,-6)
	sprite.rotation = base_angle-SWING_ARC
	damage_area.set_deferred("monitoring",true)
	if swing_tween:
		swing_tween.kill()
	swing_tween = create_tween()
	swing_tween.tween_property(sprite,"rotation",base_angle+SWING_ARC,duration)
	await swing_tween.finished
	damage_area.set_deferred("monitoring",false)
	state = State.BACK
