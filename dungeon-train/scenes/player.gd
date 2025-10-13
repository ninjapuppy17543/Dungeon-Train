extends CharacterBody2D
@export var speed := 180.0
@onready var weapon := $Weapon
@onready var health := $Health


func _ready() -> void:
	add_to_group("player")
	if health:
		health.connect("died", Callable(self, "_on_died"))


func _physics_process(_dt: float) -> void:
	var dir = Vector2(
	Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
	Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = dir * speed
	move_and_slide()


func _on_died() -> void:
	var main := get_tree().get_first_node_in_group("Main")
	# Fallback: call by path
	if not main:
		main = get_tree().root.get_child(0)
	if main and main.has_method("game_over"):
		main.call("game_over")
		queue_free()
