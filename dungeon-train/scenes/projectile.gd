extends Area2D

@export var base_damage: int = 1			# 2 = one full heart (half-hearts units)
@export var lifetime: float = 1.5
@export var bullet_speed: float = 300.0
@export var damage_number_scene: PackedScene	# assign your existing DamageNumber.tscn (Label root)

var vel: Vector2 = Vector2.ZERO
var _life_left: float = 0.0

func launch(dir: Vector2, speed: float) -> void:
	vel = dir.normalized() * speed
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr:
		spr.rotation = vel.angle()

func _ready() -> void:
	_life_left = lifetime
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(dt: float) -> void:
	global_position += vel * dt
	_life_left -= dt
	if _life_left <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Enemy bodies or World
	if body.is_in_group("enemies"):
		_hit_enemy_node(body)	# <-- ONE arg
	else:
		queue_free()  # world/anything else → pop

func _on_area_entered(area: Area2D) -> void:
	# If you touch an enemy Area2D child by accident, climb to the body
	var parent: Node = area.get_parent()
	if parent and parent.is_in_group("enemies"):
		_hit_enemy_node(parent)	# <-- ONE arg

func _hit_enemy_node(enemy: Node) -> void:
	# 1) apply damage
	var h: Node = enemy.get_node_or_null("Health")
	if h and h.has_method("apply_damage"):
		h.call("apply_damage", base_damage)

	# 2) optional knockback along bullet direction
	if enemy.has_method("apply_knockback"):
		enemy.call("apply_knockback", vel, 140.0)

	# 3) spawn floating number — same guarded pattern as your sword
	if damage_number_scene:
		var dn: Node = damage_number_scene.instantiate()
		if dn:
			get_tree().current_scene.add_child(dn)
			var enemy2d: Node2D = enemy as Node2D
			if enemy2d:
				var ci: CanvasItem = dn as CanvasItem	# works for Label (Control)
				if ci:
					ci.global_position = enemy2d.global_position + Vector2(0, -8)
			if dn.has_method("show_number"):
				dn.call("show_number", base_damage, false)  # set true if you add crits later

	# 4) remove the bullet
	queue_free()
