extends Node
class_name Health

signal health_changed(max_hearts: int, current_half_hearts: int)
signal died

@export var max_hearts: int = 3					# 1 heart = 2 half-hearts
@export var start_full: bool = true
@export var hurt_i_frames: float = 0.0			# optional invulnerability after hit

var current_half_hearts: int = 0
var _iframes_left: float = 0.0

func _ready() -> void:
	if start_full:
		current_half_hearts = max_hearts * 2
	else:
		current_half_hearts = clamp(current_half_hearts, 0, max_hearts * 2)
	emit_signal("health_changed", max_hearts, current_half_hearts)

func _process(dt: float) -> void:
	if _iframes_left > 0.0:
		_iframes_left -= dt

func apply_damage(half_hearts: int) -> void:
	if half_hearts <= 0:
		return
	if _iframes_left > 0.0:
		return

	current_half_hearts = clamp(current_half_hearts - half_hearts, 0, max_hearts * 2)
	emit_signal("health_changed", max_hearts, current_half_hearts)

	if current_half_hearts <= 0:
		emit_signal("died")
	else:
		_iframes_left = hurt_i_frames

func heal(half_hearts: int) -> void:
	if half_hearts <= 0:
		return
	current_half_hearts = clamp(current_half_hearts + half_hearts, 0, max_hearts * 2)
	emit_signal("health_changed", max_hearts, current_half_hearts)

func fill_full() -> void:
	current_half_hearts = max_hearts * 2
	emit_signal("health_changed", max_hearts, current_half_hearts)
