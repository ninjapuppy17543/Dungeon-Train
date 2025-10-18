# res://combat_layers.gd
extends Node
class_name CombatLayers

# 1-based layer indices (match Project Settings)
const LAYER_WORLD   : int = 1
const LAYER_ENEMIES : int = 2
const LAYER_HURTBOX : int = 3
const LAYER_HITBOX  : int = 4

# Groups
const GROUP_HITBOX  : StringName = &"hitbox"
const GROUP_HURTBOX : StringName = &"hurtbox"

static func bit(n: int) -> int:
	# Convert 1-based layer index to the correct bit
	return 1 << (n - 1)
