extends Node2D

@export var projectile_scene: PackedScene = preload("res://scenes/Projectile.tscn")
@export var fire_rate: float = 0.12    # lower = faster auto-fire
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
	if not projectile_scene:
		push_error("[Weapon] projectile_scene not set")
		return
	var p: Node2D = projectile_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	var dir: Vector2 = Vector2.RIGHT.rotated(rotation)
	if p.has_method("launch"):
		p.call("launch", dir, bullet_speed)
