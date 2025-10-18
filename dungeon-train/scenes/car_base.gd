extends Node2D
signal request_next
signal request_prev
signal car_cleared

@export var start_cleared: bool = false

@onready var spawner: Node = get_node_or_null("Spawner")
@onready var door_sprite: Sprite2D = get_node_or_null("Doors/ExitDoor/Sprite2D")
@onready var exit_door_cs: CollisionShape2D = get_node_or_null("Doors/ExitDoor/CollisionShape2D")
@onready var exit_trigger: Area2D = get_node_or_null("ExitTrigger")
@onready var prev_trigger: Area2D = get_node_or_null("PrevTrigger")

var _since_load: float = 0.0
const PREV_GRACE := 0.35
const EXIT_GRACE := 0.25
var _is_cleared: bool = false
var _watch_armed: bool = false
var _exit_used: bool = false
var _prev_used: bool = false

func _process(dt: float) -> void:
	_since_load += dt

func _ready() -> void:
	_since_load = 0.0
	if door_sprite: door_sprite.visible = false
	if exit_door_cs: exit_door_cs.set_deferred("disabled", false)

	# triggers basic setup (as you had)
	if exit_trigger:
		exit_trigger.set_deferred("monitoring", false)
		exit_trigger.set_deferred("collision_mask", 1 << 1) # Player layer
		var cb_next := Callable(self, "_on_exit_trigger_body_entered")
		if not exit_trigger.body_entered.is_connected(cb_next):
			exit_trigger.body_entered.connect(cb_next)
	if prev_trigger:
		prev_trigger.set_deferred("monitoring", true)
		prev_trigger.set_deferred("collision_mask", 1 << 1)
		var cb_prev := Callable(self, "_on_prev_trigger_body_entered")
		if not prev_trigger.body_entered.is_connected(cb_prev):
			prev_trigger.body_entered.connect(cb_prev)

	# START wave unless start_cleared
	if start_cleared:
		print("[Car] start_cleared=true → unlock exit")
		_mark_cleared()
	else:
		if spawner and spawner.has_method("begin_wave"):
			print("[Car] calling Spawner.begin_wave()")
			spawner.call_deferred("begin_wave")
		else:
			print("[Car] WARNING: No Spawner or begin_wave missing")
		_arm_and_watch()

func _arm_and_watch() -> void:
	await get_tree().create_timer(0.25).timeout
	_watch_armed = true
	_watch_until_clear()

func _watch_until_clear() -> void:
	if _is_cleared: return
	if not _watch_armed:
		await get_tree().create_timer(0.05).timeout
		_watch_until_clear()
		return
	var no_enemies := get_tree().get_nodes_in_group("enemies").is_empty()
	if no_enemies:
		_mark_cleared()
	else:
		await get_tree().create_timer(0.25).timeout
		_watch_until_clear()

func _mark_cleared() -> void:
	if _is_cleared: return
	_is_cleared = true
	if spawner and spawner.has_method("stop"):
		spawner.call("stop")
	if door_sprite:
		door_sprite.visible = true
	if exit_door_cs:
		exit_door_cs.set_deferred("disabled", true)
	if exit_trigger:
		exit_trigger.set_deferred("monitoring", true)
	emit_signal("car_cleared")
	print("[Car] CLEARED: exit unlocked")

func _on_exit_trigger_body_entered(body: Node) -> void:
	if _exit_used: return
	if _since_load < EXIT_GRACE: return
	if body.is_in_group("player"):
		_exit_used = true
		if exit_trigger: exit_trigger.set_deferred("monitoring", false)
		emit_signal("request_next")

func _on_prev_trigger_body_entered(body: Node) -> void:
	if _since_load < PREV_GRACE or _prev_used: return
	if body.is_in_group("player"):
		_prev_used = true
		if prev_trigger: prev_trigger.set_deferred("monitoring", false)
		emit_signal("request_prev")
