@tool
extends TextureRect

@onready var audio_ls := $AudioPlayerLipsync

var mouth_shapes := {
	0: preload("res://addons/baked_lipsync/images/preview_images/lisa-X.png"),
	1: preload("res://addons/baked_lipsync/images/preview_images/lisa-A.png"),
	2: preload("res://addons/baked_lipsync/images/preview_images/lisa-B.png"),
	3: preload("res://addons/baked_lipsync/images/preview_images/lisa-C.png"),
	4: preload("res://addons/baked_lipsync/images/preview_images/lisa-D.png"),
	5: preload("res://addons/baked_lipsync/images/preview_images/lisa-E.png"),
	6: preload("res://addons/baked_lipsync/images/preview_images/lisa-F.png"),
	7: preload("res://addons/baked_lipsync/images/preview_images/lisa-G.png"),
	8: preload("res://addons/baked_lipsync/images/preview_images/lisa-H.png"),
}


func _on_audio_player_lipsync_mouth_shape_changed(shape_index: int) -> void:
	texture = mouth_shapes[shape_index] if shape_index in mouth_shapes else mouth_shapes[0]


func play_lipsync(lipsync_source: AudioStreamLipsync):
	if audio_ls.playing:
		audio_ls.stop_lipsync()
	audio_ls.play_lipsync(lipsync_source)


func stop_preview():
	if audio_ls.playing:
		audio_ls.stop_lipsync()
	
