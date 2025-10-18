extends Label

@export var rise_speed: float = 60.0
@export var lifetime: float = 0.6
@export var normal_color: Color = Color(1, 1, 1, 1)
@export var crit_color: Color = Color(1, 0.2, 0.2, 1)
@export var font: FontFile

var _t: float = 0.0

func _ready() -> void:
	if font:
		add_theme_font_override("font", font)

func show_number(amount: int, is_crit: bool = false) -> void:
	text = str(amount)
	modulate = crit_color if is_crit else normal_color
	scale = Vector2(1.25, 1.25) if is_crit else Vector2(1, 1)

func _process(dt: float) -> void:
	_t += dt
	# move up
	global_position = Vector2(global_position.x, global_position.y - rise_speed * dt)

	# fade out
	var a: float = clamp(1.0 - (_t / lifetime), 0.0, 1.0)
	var col: Color = modulate
	col.a = a
	modulate = col

	if _t >= lifetime:
		queue_free()
