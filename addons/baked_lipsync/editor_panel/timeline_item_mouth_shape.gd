@tool
extends Control

@export var time_position_start := 0.0
@export var time_position_end := 0.0
@export var is_last_item := false

var shape_icons := {
	"X": preload("res://addons/baked_lipsync/images/icons/shape-X.png"),
	"A": preload("res://addons/baked_lipsync/images/icons/shape-A.png"),
	"B": preload("res://addons/baked_lipsync/images/icons/shape-B.png"),
	"C": preload("res://addons/baked_lipsync/images/icons/shape-C.png"),
	"D": preload("res://addons/baked_lipsync/images/icons/shape-D.png"),
	"E": preload("res://addons/baked_lipsync/images/icons/shape-E.png"),
	"F": preload("res://addons/baked_lipsync/images/icons/shape-F.png"),
	"G": preload("res://addons/baked_lipsync/images/icons/shape-G.png"),
	"H": preload("res://addons/baked_lipsync/images/icons/shape-H.png"),
}
var shape_letters := ["X", "A", "B", "C", "D", "E", "F", "G", "H"]


func set_shape(shape: String):
	if not shape in shape_letters:
		shape = "X"
	
	$Icon.texture = shape_icons[shape] 
	$Label.text = shape #shape_letters[shape]


func update_position_from_zoom(pixels_per_second: int):
	position.x = time_position_start * pixels_per_second
	if is_last_item:
		size.x = max(get_parent().size.x - position.x, 32)
	else:
		size.x = time_position_end * pixels_per_second - position.x
