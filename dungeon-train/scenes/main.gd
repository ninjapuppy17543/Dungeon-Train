extends Node

@export var ui_path: NodePath = NodePath("CanvasLayer/Control")
@export var normal_car: PackedScene = preload("res://scenes/Car_Base.tscn")
@export var boss_car: PackedScene   = preload("res://scenes/BossCar.tscn") # optional
@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@export var num_normal_cars: int = 7

@onready var car_holder: Node = $CarHolder
@onready var hearts_hud: Control = $CanvasLayer/HeartsHUD

var ui: Control = null

var path: Array[PackedScene] = []
var cleared: Array[bool] = []

var current_index: int = -1
var _enter_from_prev: bool = false
var _is_loading: bool = false

var player: Node2D = null

func _ready() -> void:
	randomize()
	ui = get_node_or_null(ui_path) as Control
	_build_path(num_normal_cars)
	_spawn_player()
	_load_car(0, true)

func _build_path(n: int) -> void:
	path.clear()
	for i in range(n):
		path.append(normal_car)
	# path.append(boss_car) # optional
	cleared.resize(path.size())
	for i in range(cleared.size()):
		cleared[i] = false

func _spawn_player() -> void:
	player = player_scene.instantiate() as Node2D
	add_child(player)

	var health := player.get_node_or_null("Health")
	if health:
		if not health.is_connected("died", Callable(self, "_on_player_died")):
			health.connect("died", Callable(self, "_on_player_died"))
		if not health.is_connected("health_changed", Callable(self, "_on_health_changed")):
			health.connect("health_changed", Callable(self, "_on_health_changed"))

		# Start full, then init HUD (both via safe helpers)
		_ensure_full_health(health)
		_init_hud_from_health(health)

# Safely fill to full HP if the Health script provides it (or fallback)
func _ensure_full_health(health: Node) -> void:
	if health == null: return
	if health.has_method("fill_full"):
		health.call("fill_full")
	else:
		var mh := int(health.get("max_hearts"))
		health.set("current_half_hearts", mh * 2)
		_on_health_changed(mh, mh * 2)

# Safely read values and push them to the HUD
func _init_hud_from_health(health: Node) -> void:
	if health == null: return
	var mh := int(health.get("max_hearts"))
	var ch := int(health.get("current_half_hearts"))
	_on_health_changed(mh, ch)


func _load_car(index: int, enter_from_prev: bool) -> void:
	if index < 0: return
	if index >= path.size():
		_win()
		_is_loading = false
		return

	# 1) move player back under Main before clearing the old car
	if player and player.get_parent() and player.get_parent() != self:
		player.reparent(self, true)  # keep global position

	# 2) clear old car
	for c in car_holder.get_children():
		c.queue_free()

	# 3) instance new car
	current_index = index
	_enter_from_prev = enter_from_prev

	var car := path[index].instantiate()
	if "start_cleared" in car:
		car.start_cleared = cleared[index]
	car_holder.add_child(car)

	# 4) reparent player into this car's Actors (Y-Sort container)
	var actors := car.get_node_or_null("Actors")
	if actors and player:
		player.reparent(actors, true)  # keep global position

	# 5) connect nav/clear signals (guarded)
	if car.has_signal("request_next"):
		var cbn := Callable(self, "_on_request_next")
		if not car.is_connected("request_next", cbn):
			car.connect("request_next", cbn)
	if car.has_signal("request_prev"):
		var cbp := Callable(self, "_on_request_prev")
		if not car.is_connected("request_prev", cbp):
			car.connect("request_prev", cbp)
	if car.has_signal("car_cleared"):
		var cbc := Callable(self, "_on_car_cleared")
		if not car.is_connected("car_cleared", cbc):
			car.connect("car_cleared", cbc)

	# 6) choose player spawn point
	var spawn: Node2D = null
	if _enter_from_prev:
		spawn = car.find_child("PlayerSpawn", true, false) as Node2D
	else:
		var back := car.find_child("BackSpawn", true, false) as Node2D
		spawn = back if back else car.find_child("PlayerSpawn", true, false) as Node2D
	if spawn and player:
		player.global_position = spawn.global_position

	# 7) HUD
	if ui and ui.has_method("set_car_info"):
		ui.set_car_info(current_index + 1, path.size())

	call_deferred("_unlock_loading")


func _on_car_cleared() -> void:
	if current_index >= 0 and current_index < cleared.size():
		cleared[current_index] = true

func _on_request_next() -> void:
	if _is_loading: return
	_is_loading = true
	call_deferred("_load_car", current_index + 1, true)

func _on_request_prev() -> void:
	if _is_loading: return
	if current_index > 0:
		_is_loading = true
		call_deferred("_load_car", current_index - 1, false)

func _unlock_loading() -> void:
	_is_loading = false

func _win() -> void:
	if ui and ui.has_method("show_win"):
		ui.show_win()
	get_tree().paused = true
	
func _on_health_changed(max_h: int, cur_half: int) -> void:
	if hearts_hud:
		if hearts_hud.has_method("set_max_hearts"):
			hearts_hud.call("set_max_hearts", max_h)
		if hearts_hud.has_method("set_hearts_half"):
			hearts_hud.call("set_hearts_half", cur_half)

func _on_player_died() -> void:
	print("[Main] Player died")
	get_tree().paused = true
	var ui := get_node_or_null("CanvasLayer/Control")
	if ui and ui.has_method("show_game_over"):
		ui.call("show_game_over")

func _disable_player(p: Node) -> void:
	# safest generic way:
	if p.has_method("set_process"):
		p.set_process(false)
	if p.has_method("set_physics_process"):
		p.set_physics_process(false)
	# turn off melee hitbox so it doesn't keep hitting
	var sword := p.get_node_or_null("SwordArea/CollisionShape2D")
	if sword:
		sword.set_deferred("disabled", true)
	# optionally hide or play death anim:
	var anim := p.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim:
		anim.play("death") if "death" in anim.sprite_frames.get_animation_names() else anim.stop()
