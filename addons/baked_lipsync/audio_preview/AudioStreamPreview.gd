@tool
extends TextureRect


signal generation_started
signal generation_progress(normalized_progress)
signal generation_completed

var voice_preview_generator
var stream : AudioStreamWAV = null
var stream_length := 0.0

@export_file("*.wav") var stream_path: String:
	set(new_path):
		stream_path = new_path
		_update_preview()


func _ready():
	voice_preview_generator = preload("voice_preview_generator.tscn").instantiate()
	add_child(voice_preview_generator)
	voice_preview_generator.generation_progress.connect(_on_generation_progress)
	voice_preview_generator.texture_ready.connect(_on_texture_ready)
	
	
	_update_preview()


func _update_preview():
	if not voice_preview_generator:
		return
	
	if stream_path in ["", "res://", "user://"]:
		texture = null
		return

	stream = load(stream_path)
	stream_length = stream.get_length() if stream else 0.0
	voice_preview_generator.generate_preview(stream)
	emit_signal("generation_started")

func _on_generation_progress(normalized_progress: float):
	emit_signal("generation_progress", normalized_progress)

func _on_texture_ready(image_texture):
	texture = image_texture
	emit_signal("generation_completed")
