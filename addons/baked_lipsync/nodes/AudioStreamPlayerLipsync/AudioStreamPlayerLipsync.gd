@tool
extends AudioStreamPlayer

signal mouth_shape_changed(mouth_shape: int)
signal expression_changed(expression: String)
signal lipsync_stopped

var _animation_player := AnimationPlayer.new()
var _anim := Animation.new()

var is_playing_lipsync := false


# Trick: a property setter instead of a regular method, so an AnimationPlayer
# node can call this inside the editor via updating the value

@export var mouth_shape_set: int:
	set(mouth_shape):
		print("mouth_shape: ", mouth_shape)
		mouth_shape_set = mouth_shape
		mouth_shape_changed.emit(mouth_shape)

@export var expression_set: String:
	set(expression):
		print("expression: ", expression)
		expression_set = expression
		expression_changed.emit(expression)


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
	# Track 2 -> expressions
	
	_anim.length = lipsync_source.animation.length
	
	lipsync_source.animation.copy_track(0, _anim)
	_anim.track_set_path(0, get_path_to(self))
	
	lipsync_source.animation.copy_track(1, _anim)
	_anim.track_set_path(1, NodePath(String(get_path_to(self)) + ":mouth_shape_set"))
	
	lipsync_source.animation.copy_track(2, _anim)
	_anim.track_set_path(2, NodePath(String(get_path_to(self)) + ":expression_set"))


func play_lipsync(lipsync_source: AudioStreamLipsync = null):
	if lipsync_source != null:
		setup(lipsync_source)
	
	is_playing_lipsync = true
	_animation_player.current_animation = "play"
	_animation_player.seek(0, true)
	_animation_player.play()
	await lipsync_stopped


func _on_animation_player_finished(anim_name: StringName):
	if not is_playing_lipsync:
		return
	
	is_playing_lipsync = false
	lipsync_stopped.emit()


func stop_lipsync():
	if not is_playing_lipsync:
		return
	is_playing_lipsync = false
	_animation_player.stop()
	lipsync_stopped.emit()
