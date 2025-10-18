extends Node2D

@export var enemy_scene: PackedScene
@export var total_enemies: int = 6
@export var spawn_interval: float = 1.0

var _running: bool = false
var _spawned: int = 0

func _ready() -> void:
	# Print where we are and what we see
	var actors := _find_actors()
	var sps := _find_spawnpoints()
	print("[Spawner] ready. enemy_scene:", enemy_scene, 
		" actors:", actors, 
		" spawnpoints:", (sps.get_child_count() if sps else -1))

func begin_wave() -> void:
	if enemy_scene == null:
		print("[Spawner] ERROR: enemy_scene not assigned!")
		return
	_running = true
	_spawned = 0
	print("[Spawner] begin_wave total:", total_enemies, " interval:", spawn_interval)
	_spawn_loop()

func stop() -> void:
	_running = false
	print("[Spawner] stop()")

func _spawn_loop() -> void:
	if not _running: 
		print("[Spawner] stopped."); 
		return
	if _spawned >= total_enemies: 
		print("[Spawner] finished. Spawned:", _spawned)
		return

	_spawn_one()
	_spawned += 1
	await get_tree().create_timer(spawn_interval).timeout
	_spawn_loop()

func _spawn_one() -> void:
	var enemy := enemy_scene.instantiate()
	if enemy == null:
		print("[Spawner] ERROR: instantiate returned null")
		return

	# Parent under Car/Actors if present (for Y-sort)
	var actors := _find_actors()
	if actors:
		actors.add_child(enemy)
	else:
		add_child(enemy) # fallback

	# Pick a spawn point
	var pos := global_position
	var sps := _find_spawnpoints()
	if sps and sps.get_child_count() > 0:
		var idx := randi() % sps.get_child_count()
		var sp := sps.get_child(idx) as Node2D
		if sp:
			pos = sp.global_position
		print("[Spawner] spawning at index:", idx, " pos:", pos)
	else:
		print("[Spawner] no SpawnPoints found; using Spawner position:", pos)

	# Place enemy
	var e2d := enemy as Node2D
	if e2d:
		e2d.global_position = pos

# ------- helpers --------

func _find_actors() -> Node2D:
	# Walk up until we find a node that has an "Actors" child
	var n: Node = self
	while n:
		var actors := n.get_node_or_null("Actors") as Node2D
		if actors:
			return actors
		n = n.get_parent()
	return null

func _find_spawnpoints() -> Node:
	# Find a child named "SpawnPoints" anywhere under the Car
	var car_root := _find_car_root()
	if car_root:
		return car_root.find_child("SpawnPoints", true, false)
	return null

func _find_car_root() -> Node:
	# Car is the Node2D that owns Spawner (or ancestor)
	var n: Node = self
	while n:
		# Heuristic: the car has an Actors child and usually a TileMap
		if n.get_node_or_null("Actors"):
			return n
		n = n.get_parent()
	return null
