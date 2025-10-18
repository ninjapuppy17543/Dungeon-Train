extends CharacterBody2D

@export var speed: float = 140.0
@export var sword_knockback: float = 180.0   # tweak in Inspector
@export var sword_damage: int = 1
@export var attack_cooldown: float = 0.35
@export var attack_windup: float = 0.06
@export var attack_active_time: float = 0.12
@export var sword_offset_x: float = 12.0
@export var crit_chance: float = 0.15              # 15% crit chance
@export var crit_multiplier: float = 2.0           # crit = 2x damage
@export var damage_number_scene: PackedScene       # assign DamageNumber.tscn in Inspector


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_area: Area2D = $SwordArea
@onready var sword_shape: CollisionShape2D = $SwordArea/CollisionShape2D

var last_facing_right: bool = true
var _attacking: bool = false
var _cooldown: float = 0.0
var _hit_this_swing: Dictionary = {}   # <— typed

func _ready() -> void:
	add_to_group("player")
	if anim:
		anim.play("idle")
		anim.flip_h = false
	_set_sword_active(false)
	if sword_area:
		if not sword_area.body_entered.is_connected(_on_sword_body_entered):
			sword_area.body_entered.connect(_on_sword_body_entered)
		if not sword_area.area_entered.is_connected(_on_sword_area_entered):
			sword_area.area_entered.connect(_on_sword_area_entered)

func _physics_process(dt: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= dt

	var x: float = Input.get_axis("ui_left", "ui_right")
	var y: float = Input.get_axis("ui_up", "ui_down")
	var dir: Vector2 = Vector2(x, y).normalized()
	velocity = dir * speed
	move_and_slide()

	if abs(x) > 0.1:
		last_facing_right = (x > 0.0)

	_update_sword_side()

	var moving: bool = velocity.length() > 0.1
	if not _attacking and anim:
		if moving and anim.animation != "run":
			anim.play("run")
		if not moving and anim.animation != "idle":
			anim.play("idle")

	if Input.is_action_just_pressed("attack"):
		_try_attack()

func _try_attack() -> void:
	if _attacking or _cooldown > 0.0:
		return
	_attacking = true
	_cooldown = attack_cooldown
	_hit_this_swing.clear()

	if anim:
		anim.play("attack")

	await get_tree().create_timer(attack_windup).timeout
	_set_sword_active(true)
	await get_tree().create_timer(attack_active_time).timeout
	_set_sword_active(false)
	await get_tree().create_timer(0.05).timeout
	_attacking = false

func _set_sword_active(on: bool) -> void:
	if sword_shape:
		sword_shape.set_deferred("disabled", not on)

func _update_sword_side() -> void:
	if anim:
		anim.flip_h = not last_facing_right
	if sword_area:
		var ox: float = absf(sword_offset_x)
		sword_area.position.x = ox if last_facing_right else -ox

func _on_sword_body_entered(body: Node) -> void:
	_apply_melee_hit(body)

func _on_sword_area_entered(area: Area2D) -> void:
	_apply_melee_hit(area)

func _apply_melee_hit(target: Node) -> void:
	if sword_shape and sword_shape.disabled:
		return
	if _hit_this_swing.has(target):
		return

	# Resolve to the owning node (handles hurtbox Areas)
	var enemy_node: Node = target
	if enemy_node is Area2D and enemy_node.get_parent():
		enemy_node = enemy_node.get_parent()

	# >>> IMPORTANT: only hit enemies
	if not enemy_node.is_in_group("enemies"):
		return

	_hit_this_swing[target] = true

	var health_node: Node = enemy_node.get_node_or_null("Health")
	if health_node and health_node.has_method("apply_damage"):
		# crit + damage
		var is_crit: bool = randf() < crit_chance
		var dmg_f: float = float(sword_damage) * (crit_multiplier if is_crit else 1.0)
		var dmg_i: int = int(round(dmg_f))
		health_node.apply_damage(dmg_i)

		# knockback (optional)
		if enemy_node.has_method("apply_knockback"):
			var dir: Vector2 = (enemy_node.global_position - global_position)
			enemy_node.apply_knockback(dir, sword_knockback)

		# floating number (guarded)
		if damage_number_scene:
			var dn := damage_number_scene.instantiate()
			if dn:
				get_tree().current_scene.add_child(dn)
				var enemy2d := enemy_node as Node2D
				if enemy2d:
					var ci := dn as CanvasItem
					if ci:
						ci.global_position = enemy2d.global_position + Vector2(0, -8)
				if dn.has_method("show_number"):
					dn.call("show_number", dmg_i, is_crit)
