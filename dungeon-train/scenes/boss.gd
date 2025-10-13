extends Node2D
@onready var health := $Health


func _ready() -> void:
	if health:
		health.connect("died", Callable(self, "_on_dead"))


func _on_dead() -> void:
	# Clear leftovers so Car detects empty
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
