extends Node


@onready var car_holder: Node = $CarHolder
@onready var ui: Control = $CanvasLayer/UI


var player_scene: PackedScene = preload("res://scenes/Player.tscn")
var car_scene: PackedScene = preload("res://scenes/Car_Base.tscn")
var boss_scene: PackedScene = preload("res://scenes/BossCar.tscn")


var path: Array[PackedScene] = []
var current_index := -1
var player: Node = null


func _ready() -> void:
	randomize()
	_build_path(7) # 7 normal cars + 1 boss
	_spawn_player()
	_load_next_car()


func _build_path(n: int) -> void:
	path.clear()
# Duplicate the same Car scene N times (you can add variants later)
	for i in range(n):
		path.append(car_scene)
		path.append(boss_scene)


func _spawn_player() -> void:
	player = player_scene.instantiate()
	add_child(player)


func _load_next_car() -> void:
	current_index += 1
	if current_index >= path.size():
		_win()
		return  # ← nothing after this in this branch

	# ---- everything below only runs when we did NOT return ----
	for c in car_holder.get_children():
		c.queue_free()

	var car = path[current_index].instantiate()
	car_holder.add_child(car)

	var spawn: Node2D = car.get_node_or_null("PlayerSpawn")
	if spawn:
		player.global_position = spawn.global_position

	ui.call("set_car_info", current_index + 1, path.size())
	car.connect("car_cleared", Callable(self, "_load_next_car"))


func _win() -> void:
	ui.call("show_win")


func game_over() -> void:
	ui.call("show_game_over")
	get_tree().paused = true
