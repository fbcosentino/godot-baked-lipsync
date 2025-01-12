@tool
extends Node3D

const AVAILABLE_EXPRESSIONS := [
	"rest",
	"joy",
	"anger",
	"surprise",
	"upset",
]

@onready var anim_tree := $AnimationTree


func set_mouth_shape(shape: int):
	anim_tree.set("parameters/blend/blend_amount", 1.0 if shape > 0 else 0.0)
	anim_tree.set("parameters/mouth/transition_request", "state_%d" % shape)


func set_expression(expr: String):
	if expr in AVAILABLE_EXPRESSIONS:
		anim_tree.set("parameters/expression/transition_request", expr)
	else:
		anim_tree.set("parameters/expression/transition_request", "rest")
