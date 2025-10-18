extends Control

@export var heart_icon_scene: PackedScene
@export var tex_full: Texture2D
@export var tex_half: Texture2D
@export var tex_empty: Texture2D


var max_hearts: int = 3
var current_half_hearts: int = 6	# 2 * max_hearts by default

@onready var row: HBoxContainer = $Margin/Row

func _ready() -> void:
	_rebuild()

func set_max_hearts(new_max: int) -> void:
	max_hearts = max(1, new_max)
	current_half_hearts = clamp(current_half_hearts, 0, max_hearts * 2)
	_rebuild()

func set_hearts_half(new_half_value: int) -> void:
	current_half_hearts = clamp(new_half_value, 0, max_hearts * 2)
	_update_icons()

func _rebuild() -> void:
	# clear previous icons
	for child: Node in row.get_children():
		child.queue_free()

	if heart_icon_scene == null:
		push_warning("HeartsHUD: heart_icon_scene not assigned")
		return

	for i in range(max_hearts):
		var h: Control = heart_icon_scene.instantiate() as Control
		# push textures into the icon (so it never renders blank)
		if tex_full:  h.set("tex_full", tex_full)
		if tex_half:  h.set("tex_half", tex_half)
		if tex_empty: h.set("tex_empty", tex_empty)
		row.add_child(h)

	_update_icons()

func _update_icons() -> void:
	print("[HeartsHUD] painting cur_half=", current_half_hearts)  # DEBUG
	var halves_left: int = current_half_hearts
	for c: Node in row.get_children():
		var val: int = min(2, halves_left)	# 0,1,2 → empty/half/full
		halves_left -= val
		if c.has_method("set_state"):
			c.call("set_state", val)
