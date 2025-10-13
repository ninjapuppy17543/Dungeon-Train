# scenes/scripts/Hurtbox.gd  (tabs for indent)
extends Area2D

@onready var _health: Node = get_parent().get_node_or_null("Health")

func apply_hit(amount: int) -> void:
	if _health and _health.has_method("apply_damage"):
		_health.apply_damage(amount)
