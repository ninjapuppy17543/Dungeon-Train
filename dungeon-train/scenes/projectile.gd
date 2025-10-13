extends Area2D
@export var lifetime := 2.0
var vel := Vector2.ZERO


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func launch(dir: Vector2, speed: float) -> void:
	vel = dir.normalized() * speed
	if has_node("Sprite2D"):
		$Sprite2D.rotation = vel.angle()


func _process(dt: float) -> void:
	global_position += vel * dt
	lifetime -= dt
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		if area.has_method("apply_hit"):
			area.apply_hit(1)
		queue_free()
