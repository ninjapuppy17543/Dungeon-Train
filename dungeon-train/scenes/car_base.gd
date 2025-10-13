extends Node2D
signal car_cleared

@onready var spawner: Node = get_node_or_null("Spawner")
@onready var door_sprite: Sprite2D = get_node_or_null("Doors/ExitDoor/Sprite2D")
@onready var exit_door_cs: CollisionShape2D = get_node_or_null("Doors/ExitDoor/CollisionShape2D")
@onready var exit_trigger: Area2D = get_node_or_null("ExitTrigger")

func _ready() -> void:
	# Door starts invisible & locked; trigger disabled
	if door_sprite:
		door_sprite.visible = false
	if exit_door_cs:
		exit_door_cs.disabled = false   # locked (collides)
	if exit_trigger:
		exit_trigger.monitoring = false
		exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)

	# START THE WAVE (this was missing)
	if spawner and spawner.has_method("begin_wave"):
		spawner.call("begin_wave")

	# Begin watching until all enemies are gone (works for boss or spawner)
	_watch_enemies()

func _watch_enemies() -> void:
	# Clear when there are no enemies (group: "enemies") and no Boss node alive
	var enemies_empty := get_tree().get_nodes_in_group("enemies").is_empty()
	var boss := get_node_or_null("Boss")
	var boss_dead := boss == null or boss.is_queued_for_deletion()
	if enemies_empty and boss_dead:
		_show_and_unlock_exit()
	else:
		await get_tree().create_timer(0.25).timeout
		_watch_enemies()

func _show_and_unlock_exit() -> void:
	if door_sprite:
		door_sprite.visible = true
	if exit_door_cs:
		exit_door_cs.disabled = true    # unlocked (no collision)
	if exit_trigger:
		exit_trigger.monitoring = true  # now detects the player

func _on_exit_trigger_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("car_cleared")
