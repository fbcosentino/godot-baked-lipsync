@tool
extends SubViewportContainer

@onready var audio_ls := $SubViewport/Node3D/AudioStreamPlayerLipsync

func _on_audio_stream_player_lipsync_mouth_shape_changed(mouth_shape: int) -> void:
	$SubViewport/Node3D/ShapeTester.set_mouth_shape(mouth_shape)


func play_lipsync(lipsync_source: AudioStreamLipsync):
	if audio_ls.playing:
		audio_ls.stop_lipsync()
	audio_ls.play_lipsync(lipsync_source)


func stop_preview():
	if audio_ls.playing:
		audio_ls.stop_lipsync()
