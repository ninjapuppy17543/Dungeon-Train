extends Control
@onready var car_label: Label = $MarginContainer/HBoxContainer/CarLabel
@onready var status_label: Label = $MarginContainer/HBoxContainer/StatusLabel


func set_car_info(i: int, total: int) -> void:
	if car_label:
		car_label.text = "Car %d / %d" % [i, total]


func show_win() -> void:
	if status_label:
		status_label.text = "YOU WIN"


func show_game_over() -> void:
	if status_label:
		status_label.text = "GAME OVER"
