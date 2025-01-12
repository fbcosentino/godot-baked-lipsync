@tool
extends TextureRect

signal expression_changed(expression: String)

@onready var audio_ls := $AudioPlayerLipsync

var mouth_shapes := [
	# Mouth totally closed
	preload("res://addons/baked_lipsync/images/preview_images/puppet_head_X.png"),
	
	# Mouth slightly open
	preload("res://addons/baked_lipsync/images/preview_images/puppet_head_C.png"),
	
	# Mouth widely open
	preload("res://addons/baked_lipsync/images/preview_images/puppet_head_D.png"),
]


func _on_audio_player_lipsync_mouth_shape_changed(shape_index: int) -> void:
	match shape_index:
		0, 1, 7: # shapes X, A, G
			texture = mouth_shapes[0]
		2, 5, 6, 8: # shapes B, E, F, H
			texture = mouth_shapes[1]
		3, 4: # shapes C, D
			texture = mouth_shapes[2]


func _on_audio_player_lipsync_expression_changed(expression: String) -> void:
	expression_changed.emit(expression)


func play_lipsync(lipsync_source: AudioStreamLipsync, start: float = 0.0):
	if audio_ls.playing:
		audio_ls.stop_lipsync()
	audio_ls.play_lipsync(lipsync_source, start)


func stop_preview():
	if audio_ls.playing:
		audio_ls.stop_lipsync()
