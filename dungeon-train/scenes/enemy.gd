extends CharacterBody2D

@export var speed: float = 80.0
@export var contact_damage: int = 1
@export var touch_cooldown: float = 0.6

@onready var target: Node2D = get_tree().get_first_node_in_group("player") as Node2D
@onready var health: Node = $Health
@onready var attack_area: Area2D = $AttackArea

var _touch_cd: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	if health:
		health.connect("died", Callable(self, "_on_dead"))
	if attack_area:
		attack_area.body_entered.connect(_on_attack_body_entered)

func _physics_process(dt: float) -> void:
	if _touch_cd > 0.0:
		_touch_cd -= dt
	if not target:
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func _on_attack_body_entered(body: Node) -> void:
	# Damage the Player when they enter the attack area (with cooldown)
	var pl := body as CharacterBody2D
	if pl:
		var dir: Vector2 = (pl.global_position - global_position).normalized()
		pl.velocity += dir * 120.0  # small, short-lived nudge
	if _touch_cd > 0.0:
		return
	if body.is_in_group("player"):
		var h: Node = body.get_node_or_null("Health")
		if h and h.has_method("apply_damage"):
			h.apply_damage(contact_damage)
			print("Hit player for ", contact_damage)  # ← add this line here
			_touch_cd = touch_cooldown


func _on_dead() -> void:
	queue_free()
