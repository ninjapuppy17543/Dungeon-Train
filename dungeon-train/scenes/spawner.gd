extends Node
@export var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@export var total_enemies := 12
@export var spawn_interval := 1.0

var _spawned := 0
var _running := false
var _points: Node2D = null

func _ready() -> void:
	_points = (get_parent() as Node).find_child("SpawnPoints", true, false) as Node2D
	if _points:
		print("[Spawner] Found SpawnPoints with", _points.get_child_count(), "children.")
	else:
		push_error("[Spawner] Could not find 'SpawnPoints' under this Car.")

func begin_wave() -> void:
	print("[Spawner] begin_wave  enemy_scene:", enemy_scene, "  interval:", spawn_interval, "  total:", total_enemies)
	_running = true
	_spawn_loop()

func _spawn_loop() -> void:
	if not _running:
		print("[Spawner] stopped.")
		return
	if _spawned >= total_enemies:
		print("[Spawner] finished. Spawned:", _spawned)
		_running = false
		return
	if not enemy_scene:
		push_error("[Spawner] enemy_scene is NULL. Assign it in Inspector or keep preload.")
		_running = false
		return
	if not _points or _points.get_child_count() == 0:
		push_error("[Spawner] No SpawnPoints or zero children.")
		_running = false
		return

	_spawn_one()
	_spawned += 1
	await get_tree().create_timer(spawn_interval).timeout
	_spawn_loop()

func _spawn_one() -> void:
	var idx := randi() % _points.get_child_count()
	var p := _points.get_child(idx) as Node2D
	print("[Spawner] Spawning at index", idx, " pos:", p.global_position)
	var e := enemy_scene.instantiate() as Node2D
	get_parent().add_child(e)  # under the Car
	e.global_position = p.global_position
