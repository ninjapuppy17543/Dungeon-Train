extends CharacterBody2D

# --- Movement / Combat ---
@export var speed: float = 80.0
@export var contact_damage: int = 1          # damage to Player when inside AttackArea
@export var touch_cooldown: float = 0.6      # seconds between contact damage ticks

@export var max_run_speed: float = 140.0        # clamp chase speed
@export var max_knockback_speed: float = 220.0  # clamp knockback bursts

@export var death_poof_scene: PackedScene

# --- Knockback (from sword/bullets) ---
@export var knockback_resist: float = 0.2    # 0 = full force, 1 = immune
@export var knockback_decay: float = 180.0    # higher = fades faster

# --- Anti-stick "tangent drift" (sideways slide when very close) ---
@export var drift_distance: float = 20.0     # start drifting when closer than this (pixels)
@export var drift_strength: float = 60.0     # sideways speed added when close

@export var kb_iterations: int = 3   # small number of micro-steps per frame


# --- Node refs (optional but helpful) ---
@onready var target: Node2D = get_tree().get_first_node_in_group("player") as Node2D
@onready var health: Node = get_node_or_null("Health")
@onready var attack_area: Area2D = get_node_or_null("AttackArea")
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

# --- Internals ---
var _touch_cd: float = 0.0
var _kb: Vector2 = Vector2.ZERO		# knockback velocity contribution

func _ready() -> void:
	add_to_group("enemies")
	if anim: anim.play("walk")
	if health:
		health.connect("died", Callable(self, "_on_dead"))

	if attack_area:
		if not attack_area.body_entered.is_connected(_on_attack_body_entered):
			attack_area.body_entered.connect(_on_attack_body_entered)
		if not attack_area.body_exited.is_connected(_on_attack_body_exited):
			attack_area.body_exited.connect(_on_attack_body_exited)
	print("[Enemy] AttackArea ready. monitoring=", attack_area and attack_area.monitoring, " dmg=", contact_damage)

func _physics_process(dt: float) -> void:
	# cooldown
	if _touch_cd > 0.0:
		_touch_cd -= dt

	# 1) Build desired velocity (chase + tangent drift)
	var chase: Vector2 = Vector2.ZERO
	if target:
		var to_p: Vector2 = target.global_position - global_position
		var d: float = to_p.length()
		var dir: Vector2 = (to_p / d) if d > 0.001 else Vector2.ZERO
		chase = dir * speed

		# anti-stick side drift (when very close)
		if d < drift_distance and d > 0.0:
			var tangent := Vector2(-dir.y, dir.x)
			chase += tangent * drift_strength

	# clamp speeds
	chase = chase.limit_length(max_run_speed)
	_kb    = _kb.limit_length(max_knockback_speed)

	var desired_vel: Vector2 = chase + _kb
	if anim and absf(desired_vel.x) > 0.1:
# 		anim.flip_h = (desired_vel.x < 0.0)
		anim.flip_h = desired_vel.x < 0.0

	# 2) Collision-safe movement in micro-steps using move_and_collide (NOT test_only)
	var motion: Vector2 = desired_vel * dt
	var remaining: float = motion.length()
	var max_step: float = 6.0  # pixels per micro-step (tweak 4–8 if needed)

	if remaining <= max_step:
		_do_collide_step(motion)  # will actually move
	else:
		var dir_step: Vector2 = motion / remaining
		while remaining > 0.001:
			var step_len: float = min(remaining, max_step)
			var step: Vector2 = dir_step * step_len
			var blocked: float = _do_collide_step(step)
			remaining -= step_len
			# If fully blocked along the normal, break to avoid tiny loops
			if step_len > 0.0 and blocked >= step_len * 0.999:
				break

	# 3) Decay knockback
	_kb = _kb.move_toward(Vector2.ZERO, knockback_decay * dt)



func _on_attack_body_entered(body: Node) -> void:
	print("[Enemy] AttackArea ENTER:", body, " groups=", body.get_groups())
	if body.is_in_group("player"):
		_try_damage_player(body)

func _on_attack_body_exited(body: Node) -> void:
	print("[Enemy] AttackArea EXIT:", body)

func _try_damage_player(body: Node) -> void:
	if _touch_cd > 0.0:
		print("[Enemy] on cooldown:", _touch_cd)
		return
	var h: Node = body.get_node_or_null("Health")
	if h and h.has_method("apply_damage"):
		print("[Enemy] damaging player for ", contact_damage, " half-hearts")
		h.apply_damage(contact_damage)  # 1 = half-heart, 2 = full heart
		_touch_cd = touch_cooldown
	else:
		print("[Enemy] Player has no Health or no apply_damage()")

# Called by bullets/sword
func apply_knockback(dir: Vector2, force: float) -> void:
	var k: Vector2 = dir.normalized() * maxf(force, 0.0)
	_kb += k * (1.0 - clampf(knockback_resist, 0.0, 1.0))

func _on_dead() -> void:
	_spawn_poof()
	queue_free()
	
# Perform one collision-safe step and slide along walls.
# Returns how much of 'step' was cancelled along a collision normal.
func _do_collide_step(step: Vector2) -> float:
	if step.length() <= 0.0:
		return 0.0

	# IMPORTANT: test_only = false (default). This actually moves the body.
	var col := move_and_collide(step)  # no 'true' flags here!
	if col:
		var n: Vector2 = col.get_normal()
		# remove knockback pushing INTO the wall
		var push := _kb.dot(n)
		if push > 0.0:
			_kb -= n * push

		# slide the remainder tangentially along the wall
		var remainder: Vector2 = step.slide(n)
		if remainder.length() > 0.0:
			move_and_collide(remainder)  # actually move the slid remainder
		return step.length() - remainder.length()
	else:
		# moved full step, no collision
		return 0.0


func _spawn_poof() -> void:
	if death_poof_scene == null:
		print("[Enemy] death_poof_scene not assigned")
		return
	var fx := death_poof_scene.instantiate()
	if fx == null:
		print("[Enemy] instantiate() returned null for death poof")
		return

	# prefer current parent (e.g., Car/Actors) so position is correct even if scene changes
	var parent := get_parent()
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(fx)

	# position it at the enemy’s location
	var ci := fx as CanvasItem
	if ci:
		ci.global_position = global_position
	elif fx is Node2D:
		(fx as Node2D).global_position = global_position
