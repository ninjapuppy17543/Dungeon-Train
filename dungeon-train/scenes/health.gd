extends Node
signal died
@export var max_hp := 5
var hp := 0


func _ready() -> void:
	hp = max_hp


func apply_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hp == 0:
		emit_signal("died")


# For projectiles hitting Hurtbox (Area2D)
func apply_hit(amount: int) -> void:
	apply_damage(amount)
