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

func create_animation(audio_file: String, lipsync_data: Array):
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
	# Track 1 -> funcion calls
	
	var track_index = anim.add_track(Animation.TYPE_AUDIO)
	anim.track_set_path(track_index, ".")
	anim.audio_track_insert_key(track_index, 0.0, audio_stream)
	
	track_index = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(track_index, ".")
	
	for pair in lipsync_data:
		var time: float = float(pair[0])
		var shape: int = MOUTH_SHAPE_CODES[pair[1]] if pair[1] in MOUTH_SHAPE_CODES else 0
		
		var method_data = {"method": "_mouth_shape_set", "args": [shape]} # Dark sorcery
		anim.track_insert_key(track_index, time, method_data)
	
	var anim_lib := AnimationLibrary.new()
	anim_lib.add_animation("play", anim)
	
	var audio_ls := AudioStreamLipsync.new()
	audio_ls.audio_stream = audio_stream
	audio_ls.animation = anim
	audio_ls.animation_library = anim_lib
	audio_ls.lipsync_data = lipsync_data
	
	var output_filename: String = audio_file+"-lipsync.tres"
	if FileAccess.file_exists(output_filename):
		var old_data: AudioStreamLipsync = load(output_filename)
		audio_ls.expression_data = old_data.expression_data.duplicate(true)
	
	ResourceSaver.save(audio_ls, output_filename)
	
	return output_filename
