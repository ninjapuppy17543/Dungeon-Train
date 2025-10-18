extends GPUParticles2D

func point_dir(v: Vector2) -> void:
	rotation = v.angle() + PI   # flip 180° if it was shooting backwards

func _ready() -> void:
	emitting = true
	await get_tree().create_timer(lifetime + 0.05).timeout
	queue_free()
