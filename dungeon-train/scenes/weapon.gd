extends Node2D

@export var projectile_scene: PackedScene = preload("res://scenes/Projectile.tscn")
@export var fire_rate: float = 0.5    # lower = faster auto-fire
@export var bullet_speed: float = 380.0

var _cooldown: float = 0.0

func _ready() -> void:
	print("[Weapon] ready at", global_position)

func _process(dt: float) -> void:
	# Aim toward mouse
	var mouse_world: Vector2 = get_global_mouse_position()
	rotation = (mouse_world - global_position).angle()

	# Cooldown tick
	if _cooldown > 0.0:
		_cooldown -= dt

	# Hold-to-fire (RMB mapped to 'fire' in Input Map)
	if Input.is_action_pressed("fire") and _cooldown <= 0.0:
		_fire()
		_cooldown = fire_rate

func _fire() -> void:
	if projectile_scene == null:
		return
	var p := projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)

	var dir := (get_global_mouse_position() - global_position).normalized()
	var muzzle: float = (p.muzzle_distance if "muzzle_distance" in p else 12.0)
	(p as Node2D).global_position = global_position + dir * muzzle

	if p.has_method("launch"):
		p.launch(dir, bullet_speed)
	elif "vel" in p:
		p.vel = dir * bullet_speed
