class_name LipsyncAnimationBaker
extends RefCounted

const MOUTH_SHAPE_CODES := {
	"X": 0, 
	"A": 1, 
	"B": 2, 
	"C": 3, 
	"D": 4, 
	"E": 5, 
	"F": 6, 
	"G": 7, 
	"H": 8,
}

func create_animation(audio_file: String, lipsync_data: Array = [], expression_data: Array = []):
	# Assumes lipsync_data is valid. No checks are done.
	
	var audio_stream: AudioStream = load(audio_file)
	
	# Calculates animation length
	var last_timestamp = lipsync_data[lipsync_data.size()-1][0]
	var anim_length = last_timestamp + 0.01
	var stream_length = audio_stream.get_length()
	if stream_length > anim_length:
		anim_length = stream_length
	
	
	var anim := Animation.new()
	anim.clear()
	anim.length = anim_length
	
	# Track 0 -> audio
	# Track 1 -> function calls for mouth
	# Track 2 -> function calls for expressions 
	
	var track_index = anim.add_track(Animation.TYPE_AUDIO)
	anim.track_set_path(track_index, ".")
	anim.audio_track_insert_key(track_index, 0.0, audio_stream)
	
	# Trick:
	# A method call track does not update inside the editor.
	# Instead, a value track is used, updating an @export var mouth_shape_set
	# which has a setter function, in lieu of the method call
	
	track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, ".:mouth_shape_set")
	anim.track_set_interpolation_type(track_index, Animation.INTERPOLATION_NEAREST)
	anim.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
	for pair in lipsync_data:
		var shape_time: float = float(pair[0])
		var shape: int = MOUTH_SHAPE_CODES[pair[1]] if pair[1] in MOUTH_SHAPE_CODES else 0
		anim.track_insert_key(track_index, shape_time, shape, 0)
	
	track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, ".:expression_set")
	anim.track_set_interpolation_type(track_index, Animation.INTERPOLATION_NEAREST)
	anim.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
	for pair in expression_data:
		var expression_time: float = float(pair[0])
		var expression_string: String = str(pair[1])
		anim.track_insert_key(track_index, expression_time, expression_string, 0)
	
	var anim_lib := AnimationLibrary.new()
	anim_lib.add_animation("play", anim)
	
	var audio_ls := AudioStreamLipsync.new()
	audio_ls.audio_stream = audio_stream
	audio_ls.animation = anim
	audio_ls.animation_library = anim_lib
	audio_ls.lipsync_data = lipsync_data
	audio_ls.expression_data = expression_data
	
	var output_filename: String = audio_file+"-lipsync.tres"
	#if FileAccess.file_exists(output_filename):
	#	var old_data: AudioStreamLipsync = load(output_filename)
	#	if (old_data.expression_data.size() > 0) and (expression_data.size() == 0):
	#		audio_ls.expression_data = old_data.expression_data.duplicate(true)
	
	ResourceSaver.save(audio_ls, output_filename)
	
	return output_filename


func _animation_clear_tracks(anim: Animation):
	# Clears keyframes but re-adds tracks as empty
	while anim.get_track_count() > 1:
		anim.remove_track(1)
	
	
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, ".:mouth_shape_set")
	anim.track_set_interpolation_type(track_index, Animation.INTERPOLATION_NEAREST)
	anim.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
	
	track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, ".:expression_set")
	anim.track_set_interpolation_type(track_index, Animation.INTERPOLATION_NEAREST)
	anim.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)


func update_animation(audio_ls: AudioStreamLipsync):
	# Updates the animation inside a AudioStreamLipsync resource file
	# using the data inside the resource itself
	
	var anim: Animation = audio_ls.animation
	# Track 0 -> audio
	# Track 1 -> function calls for mouth
	# Track 2 -> function calls for expressions 
	
	_animation_clear_tracks(anim)
	
	var lipsync_data: Array = audio_ls.lipsync_data
	var expression_data: Array = audio_ls.expression_data
	
	var track_index := 1
	for pair in lipsync_data:
		var shape_time: float = float(pair[0])
		var shape: int = MOUTH_SHAPE_CODES[pair[1]] if pair[1] in MOUTH_SHAPE_CODES else 0
		anim.track_insert_key(track_index, shape_time, shape, 0)
	
	track_index = 2
	for pair in expression_data:
		var expression_time: float = float(pair[0])
		var expression_string: String = str(pair[1])
		anim.track_insert_key(track_index, expression_time, expression_string, 0)
