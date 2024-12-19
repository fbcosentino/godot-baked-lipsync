@tool
extends AudioStreamPlayer3D

signal mouth_shape_changed(mouth_shape: int)
signal lipsync_stopped

var _animation_player := AnimationPlayer.new()
var _anim := Animation.new()

var is_playing_lipsync := false

func _init():
	add_child(_animation_player)
	_animation_player.owner = owner
	_animation_player.animation_finished.connect(_on_animation_player_finished)
	var anim_lib = AnimationLibrary.new()
	_animation_player.add_animation_library("", anim_lib)
	anim_lib.add_animation("play", _anim)
	_animation_player.current_animation = "play"


func setup(lipsync_source: AudioStreamLipsync):
	_anim.clear()
	
	# Track 0 -> audio
	# Track 1 -> lipsync
	
	_anim.length = lipsync_source.animation.length
	
	lipsync_source.animation.copy_track(0, _anim)
	_anim.track_set_path(0, get_path_to(self))
	
	lipsync_source.animation.copy_track(1, _anim)
	_anim.track_set_path(1, get_path_to(self))


func play_lipsync(lipsync_source: AudioStreamLipsync = null):
	if lipsync_source != null:
		setup(lipsync_source)
	
	is_playing_lipsync = true
	_animation_player.current_animation = "play"
	_animation_player.seek(0, true)
	_animation_player.play()

	await lipsync_stopped


func _mouth_shape_set(mouth_shape: int):
	mouth_shape_changed.emit(mouth_shape)


func _on_animation_player_finished(anim_name: StringName):
	if not is_playing_lipsync:
		return
	
	is_playing_lipsync = false
	lipsync_stopped.emit()


func stop_lipsync():
	if not is_playing_lipsync:
		return
		
	is_playing_lipsync = false
	lipsync_stopped.emit()
