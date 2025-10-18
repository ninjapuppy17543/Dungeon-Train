extends TextureRect

@export var tex_full: Texture2D
@export var tex_half: Texture2D
@export var tex_empty: Texture2D

func set_state(half_units: int) -> void:
	# DEBUG once: prints null if you forgot to assign
	# print("[HeartIcon] full=", tex_full, " half=", tex_half, " empty=", tex_empty)
	if half_units >= 2:
		texture = tex_full
	elif half_units == 1:
		texture = tex_half
	else:
		texture = tex_empty
