@tool
extends SubViewportContainer

signal expression_changed(expression: String)

@onready var audio_ls := $SubViewport/Node3D/AudioStreamPlayerLipsync
@onready var shape_tester := $SubViewport/Node3D/ShapeTester

func _on_audio_stream_player_lipsync_mouth_shape_changed(mouth_shape: int) -> void:
	shape_tester.set_mouth_shape(mouth_shape)


func _on_audio_stream_player_lipsync_expression_changed(expression: String) -> void:
	expression_changed.emit(expression)
	shape_tester.set_expression(expression)


func play_lipsync(lipsync_source: AudioStreamLipsync, start: float = 0.0):
	shape_tester.set_expression("rest")
	if audio_ls.playing:
		audio_ls.stop_lipsync()
	audio_ls.play_lipsync(lipsync_source, start)


func stop_preview():
	shape_tester.set_expression("rest")
	if audio_ls.playing:
		audio_ls.stop_lipsync()
