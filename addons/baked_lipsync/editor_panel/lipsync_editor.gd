@tool
extends Panel

signal lipsync_data_generated(audio_file: String, res_file: String)

const ZOOM_MAX := 10
const ZOOM_MIN := 4
const ZOOM_DEFAULT := 6

var template_item_MouthShape := preload("res://addons/baked_lipsync/editor_panel/timeline_item_mouth_shape.tscn")
var template_item_Expression := preload("res://addons/baked_lipsync/editor_panel/timeline_item_expression.tscn")

@onready var label_audio_file := $LabelAudioFile
@onready var label_res_file := $LabelResFile
@onready var label_generate_warning := $BtnGenerate/LabelWarning
@onready var timeline := $PanelExpressions/ScrollContainer/Timeline
@onready var audio_stream_preview := $PanelExpressions/ScrollContainer/Timeline/AudioStreamPreview
@onready var mouth_shapes_box := $PanelExpressions/ScrollContainer/Timeline/MouthShapesBox
@onready var expressions_box := $PanelExpressions/ScrollContainer/Timeline/ExpressionsBox

@onready var btn_generate := $BtnGenerate

var current_zoom := ZOOM_DEFAULT
var current_pixels_per_second := 64
var mouth_shapes_data := []

func load_data(audio_file_path: String, res_file_path: String):
	label_audio_file.text = audio_file_path
	label_res_file.text = res_file_path
	label_generate_warning.hide()
	audio_stream_preview.stream_path = ""
	audio_stream_preview.size.x = 600
	
	mouth_shapes_data.clear()
	
	current_zoom = ZOOM_DEFAULT
	current_pixels_per_second = (2 ** current_zoom)

	
	var has_error := false
	if (audio_file_path != "") and (not FileAccess.file_exists(audio_file_path)):
		label_audio_file.text += " (file not found)"
		has_error = true
	if (res_file_path != "") and (not FileAccess.file_exists(res_file_path)):
		label_res_file.text += " (file not found)"
		has_error = true
	if has_error:
		return
	
	if (audio_file_path != ""):
		audio_stream_preview.stream_path = audio_file_path
		btn_generate.disabled = false
	else:
		btn_generate.disabled = true
	
	if (res_file_path != ""):
		var res_data: AudioStreamLipsync = load(res_file_path)
		if not res_data:
			return
		
		if res_data.lipsync_data.size() > 0:
			mouth_shapes_data = res_data.lipsync_data
			label_generate_warning.show()
	
	_mouth_shapes_populate()
	_update_zoom()


func generate_lipsync():
	var rr = RhubarbRunner.new()
	var ab = LipsyncAnimationBaker.new()
	
	btn_generate.disabled = true
	btn_generate.text = "Generating..."
	
	await get_tree().process_frame
	
	# These are blocking calls, no need to await
	var a = (rr.convert_tsv_to_array(rr.invoke(label_audio_file.text)))
	var res_filename: String = ab.create_animation(label_audio_file.text, a)
	
	await get_tree().process_frame
	
	btn_generate.disabled = false
	btn_generate.text = "Generate Lipsync"
	
	load_data(label_audio_file.text, res_filename)
	
	call_deferred("emit_signal", ["lipsync_data_generated", label_audio_file.text, res_filename])


func _mouth_shapes_clear():
	for child in expressions_box.get_children():
		child.queue_free()


func _mouth_shapes_populate():
	var last_i = mouth_shapes_data.size()-1
	for i in range(mouth_shapes_data.size()):
		var start_time: float = mouth_shapes_data[i][0]
		var end_time: float = mouth_shapes_data[i+1][0] if i < last_i else start_time
		
		var new_item = template_item_MouthShape.instantiate()
		mouth_shapes_box.add_child(new_item)
		new_item.time_position_start = start_time
		new_item.time_position_end = end_time
		new_item.is_last_item = (i == last_i)
		
		new_item.set_shape(mouth_shapes_data[i][1])
		new_item.update_position_from_zoom(current_pixels_per_second)



func _on_btn_generate_pressed() -> void:
	generate_lipsync()


func _on_audio_stream_preview_generation_completed() -> void:
	current_zoom = ZOOM_DEFAULT
	current_pixels_per_second = (2 ** current_zoom)
	_update_zoom()


func _update_zoom():
	timeline.custom_minimum_size.x = current_pixels_per_second * audio_stream_preview.stream_length
	await get_tree().create_timer(0.05).timeout # makes sure all UI is updated
	for item in mouth_shapes_box.get_children():
		item.call_deferred("update_position_from_zoom", current_pixels_per_second)


func _on_btn_zoom_out_pressed() -> void:
	current_zoom = max(current_zoom - 1, ZOOM_MIN)
	current_pixels_per_second = (2 ** current_zoom)
	_update_zoom()


func _on_btn_zoom_reset_pressed() -> void:
	current_zoom = ZOOM_DEFAULT
	current_pixels_per_second = (2 ** current_zoom)
	_update_zoom()


func _on_btn_zoom_in_pressed() -> void:
	current_zoom = min(current_zoom + 1, ZOOM_MAX)
	current_pixels_per_second = (2 ** current_zoom)
	_update_zoom()


func _on_btn_preview_play_pressed() -> void:
	if label_res_file.text != "":
		$ShapePreview2D.play_lipsync(load(label_res_file.text))
