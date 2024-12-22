@tool
extends Control

signal move_started(node: Control)
signal move_ended(node: Control)

@export var time_position_start := 0.0
@export var time_position_end := 0.0
@export var is_last_item := false
@export var expression_item_data: Array # Stores a reference from the resource

@onready var moving_ui := $Moving

var position_x_min: int = 0
var position_x_max: int = 600
var position_offset: int = 0
var is_pressed := false
var is_moving := false


func _ready() -> void:
	moving_ui.hide()


func set_expression(expression_name: String):
	$Label.text = expression_name


func update_position_from_zoom(pixels_per_second: int):
	position.x = time_position_start * pixels_per_second
	if is_last_item:
		size.x = max(get_parent().size.x - position.x, 32)
	else:
		size.x = time_position_end * pixels_per_second - position.x


func _on_btn_move_button_down() -> void:
	position_x_max = get_parent().size.x
	position_offset = get_local_mouse_position().x
	is_pressed = true


func _on_btn_move_button_up() -> void:
	is_moving = false
	is_pressed = false
	moving_ui.hide()
	move_ended.emit(self)


func _on_btn_move_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion):
		if is_pressed and (not is_moving):
			is_moving = true
			moving_ui.show()
			move_started.emit(self)
		
		if is_moving:
			position.x = clamp(position.x + event.relative.x, position_x_min, position_x_max)


func set_selected(is_selected: bool):
	$PanelSelected.visible = is_selected
