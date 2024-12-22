@tool
extends Panel

signal lipsync_data_generated(audio_file: String, res_file: String)
signal dismissed

const ZOOM_MAX := 10
const ZOOM_MIN := 4
const ZOOM_DEFAULT := 6
const MIN_TIME_BETWEEN_EXPRESSIONS := 0.1 # in seconds

var template_item_MouthShape := preload("res://addons/baked_lipsync/editor_panel/timeline_item_mouth_shape.tscn")
var template_item_Expression := preload("res://addons/baked_lipsync/editor_panel/timeline_item_expression.tscn")

@onready var label_audio_file := $LabelAudioFile
@onready var label_res_file := $LabelResFile
@onready var label_generate_warning := $BtnGenerate/LabelWarning

@onready var panel_timeline := $PanelTimeline
@onready var timeline := $PanelTimeline/ScrollContainer/Timeline
@onready var audio_stream_preview := $PanelTimeline/ScrollContainer/Timeline/AudioStreamPreview
@onready var playback_cursor := $PanelTimeline/ScrollContainer/Timeline/PlaybackCursor

@onready var mouth_shapes_box := $PanelTimeline/ScrollContainer/Timeline/MouthShapesBox
@onready var expressions_box := $PanelTimeline/ScrollContainer/Timeline/ExpressionsBox
@onready var expression_string_edit := $PanelTimeline/ExpressionStringEdit
@onready var expression_btn_new := $PanelTimeline/BtnExpressionNew


@onready var preview_box := $PreviewBox
@onready var preview_2d := $PreviewBox/ShapePreview2D
@onready var preview_3d := $PreviewBox/ShapePreview3D
@onready var preview_3d_tip := $PreviewBox/ShapePreview3D_Tip
@onready var preview_simple := $PreviewBox/ShapePreviewSimple
@onready var preview_expression_label := $PreviewBox/LabelPreviewExpression


@onready var btn_generate := $BtnGenerate

var current_zoom := ZOOM_DEFAULT
var current_pixels_per_second := 64
var current_audio_length := 0.0
var playback_tween: Tween = null
var mouth_shapes_data := []
var expression_data := []
var selected_expression_item: Control = null
var res_data: AudioStreamLipsync = null

func load_data(audio_file_path: String, res_file_path: String):
	label_audio_file.text = audio_file_path
	label_res_file.text = res_file_path
	label_generate_warning.hide()
	audio_stream_preview.stream_path = ""
	audio_stream_preview.size.x = 600
	current_audio_length = 0.0
	res_data = null
	preview_expression_label.text = "-"
	
	panel_timeline.hide()
	preview_box.hide()
	playback_cursor.hide()
	expression_string_edit.hide()
	expression_btn_new.show()
	
	_mouth_shapes_clear()
	_expressions_clear()
	
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
		res_data = ResourceLoader.load(res_file_path, "AudioStreamLipsync", ResourceLoader.CACHE_MODE_REPLACE)
		if not res_data:
			return
		
		if res_data.lipsync_data.size() > 0:
			mouth_shapes_data = res_data.lipsync_data.duplicate(true)
			label_generate_warning.show()
		
		if res_data.expression_data.size() > 0:
			expression_data = res_data.expression_data.duplicate(true)
		
		_mouth_shapes_populate()
		_expressions_populate()
		_expressions_reorganize() # In case the resource is corrupted from manual editting
		_update_zoom()
		
		panel_timeline.show()
		stop_preview()
		preview_box.show()


func bake_animation_for_preview() -> AudioStreamLipsync:
	if (not res_data):
		return null
	
	var preview_res: AudioStreamLipsync = res_data.duplicate(true)
	
	preview_res.lipsync_data = mouth_shapes_data
	preview_res.expression_data = expression_data
	
	var ab = LipsyncAnimationBaker.new()
	ab.update_animation(preview_res)
	
	return preview_res


func save():
	if (not res_data):
		return
	
	res_data.lipsync_data = mouth_shapes_data
	res_data.expression_data = expression_data
	
	var ab = LipsyncAnimationBaker.new()
	ab.update_animation(res_data)
	
	ResourceSaver.save(res_data, label_res_file.text)


func _on_audio_stream_preview_generation_started() -> void:
	current_audio_length = audio_stream_preview.stream_length


func generate_lipsync():
	var rr = RhubarbRunner.new()
	var ab = LipsyncAnimationBaker.new()
	
	btn_generate.disabled = true
	btn_generate.text = "Generating..."
	
	await get_tree().process_frame
	
	# These are blocking calls, no need to await
	var a = (rr.convert_tsv_to_array(rr.invoke(label_audio_file.text)))
	var res_filename: String = ab.create_animation(label_audio_file.text, a, expression_data)
	
	await get_tree().process_frame
	
	btn_generate.disabled = false
	btn_generate.text = "Generate Lipsync"
	
	load_data(label_audio_file.text, res_filename)
	
	call_deferred("emit_signal", "lipsync_data_generated", label_audio_file.text, res_filename)


func _mouth_shapes_clear():
	mouth_shapes_data.clear()
	for child in mouth_shapes_box.get_children():
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


func _expressions_clear():
	expression_data.clear() # expression_data is a duplicate, not a reference to the original
	for child in expressions_box.get_children():
		child.queue_free()


func _expressions_populate():
	var last_i = expression_data.size()-1
	for i in range(expression_data.size()):
		var start_time: float = expression_data[i][0]
		var end_time: float = expression_data[i+1][0] if i < last_i else start_time
		
		_expression_add_node(expression_data[i], start_time, end_time, (i == last_i))
		
		#var new_item = template_item_Expression.instantiate()
		#expressions_box.add_child(new_item)
		#new_item.expression_item_data = expression_data[i]
		#new_item.move_started.connect(_on_expression_move_started)
		#new_item.move_ended.connect(_on_expression_move_ended)
		#new_item.time_position_start = start_time
		#new_item.time_position_end = end_time
		#new_item.is_last_item = (i == last_i)
		
		#new_item.set_expression(expression_data[i][1])
		#new_item.update_position_from_zoom(current_pixels_per_second)


func _expression_add_node(item_data: Array, start_time: float, end_time: float, is_last: bool = false) -> Control:
	var new_item = template_item_Expression.instantiate()
	expressions_box.add_child(new_item)
	new_item.expression_item_data = item_data
	new_item.move_started.connect(_on_expression_move_started)
	new_item.move_ended.connect(_on_expression_move_ended)
	new_item.time_position_start = start_time
	new_item.time_position_end = end_time
	new_item.is_last_item = is_last
	
	new_item.set_expression(str(item_data[1]))
	new_item.update_position_from_zoom(current_pixels_per_second)
	
	return new_item
	


func _expression_node_update(node: Control):
	var data_index: int = expression_data.find(node.expression_item_data)
	if data_index < 0:
		return
	
	node.time_position_start = node.expression_item_data[0]
	node.is_last_item = (data_index == (expression_data.size()-1))
	node.time_position_end = 0.0 if node.is_last_item else expression_data[data_index+1][0]
	
	node.update_position_from_zoom(current_pixels_per_second)



func _sort_timeline_items(a: Array, b: Array) -> bool:
	if a[0] < b[0]:
		return true
	else:
		return false


func _expressions_reorganize():
	# Fix array if items have changed order
	expression_data.sort_custom(_sort_timeline_items)
	
	# Fix cases of items with same timestamp (add MIN_TIME_BETWEEN_EXPRESSIONS between them)
	for i in range(1, expression_data.size()):
		var item = expression_data[i]
		var min_time = expression_data[i-1][0] + MIN_TIME_BETWEEN_EXPRESSIONS
		
		if item[0] < min_time:
			item[0] = min_time
	
	# Update nodes to the data
	for child in expressions_box.get_children():
		_expression_node_update(child)


func _on_btn_generate_pressed() -> void:
	generate_lipsync()


func _on_audio_stream_preview_generation_completed() -> void:
	current_zoom = ZOOM_DEFAULT
	current_pixels_per_second = (2 ** current_zoom)
	_update_zoom()


func _update_zoom():
	timeline.custom_minimum_size.x = current_pixels_per_second * audio_stream_preview.stream_length
	await get_tree().create_timer(0.02).timeout # makes sure all UI is updated
	timeline.size.x = timeline.custom_minimum_size.x
	audio_stream_preview.size.x = timeline.custom_minimum_size.x
	await get_tree().create_timer(0.02).timeout # makes sure all UI is updated
	for item in mouth_shapes_box.get_children():
		item.call_deferred("update_position_from_zoom", current_pixels_per_second)
	for item in expressions_box.get_children():
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
	if playback_tween:
		stop_preview()

	elif label_res_file.text != "":
		preview_expression_label.text = "-"
		
		#var res_data: AudioStreamLipsync = ResourceLoader.load(label_res_file.text, "AudioStreamLipsync", ResourceLoader.CACHE_MODE_REPLACE)
		var preview_res: AudioStreamLipsync = bake_animation_for_preview()
		if not preview_res:
			return
		
		if preview_2d.visible:
			preview_2d.play_lipsync(preview_res)
		elif preview_3d.visible:
			preview_3d.play_lipsync(preview_res)
		elif preview_simple.visible:
			preview_simple.play_lipsync(preview_res)
		
		if playback_tween:
			playback_tween.kill()
			playback_tween = null
		
		playback_cursor.position.x = 0
		
		playback_tween = create_tween()
		playback_tween.finished.connect(_on_playback_tween_finished)
		playback_tween.tween_property(playback_cursor, "position:x", current_audio_length * current_pixels_per_second, current_audio_length)
		playback_tween.play()
		playback_cursor.show()


func _on_preview_expression_changed(expression: String) -> void:
	preview_expression_label.text = expression



func _on_playback_tween_finished():
	playback_tween.kill()
	playback_tween = null
	playback_cursor.hide()


func stop_preview():
	if playback_tween:
		playback_tween.kill()
		playback_tween = null
		playback_cursor.hide()
	preview_2d.stop_preview()
	preview_3d.stop_preview()
	preview_simple.stop_preview()
	playback_cursor.hide()


func _on_btn_preview_style_item_selected(index: int) -> void:
	preview_2d.visible     = (index == 0)
	preview_3d.visible     = (index == 1)
	preview_3d_tip.visible = preview_3d.visible
	preview_simple.visible = (index == 2)


func _on_expression_move_started(node: Control):
	for child: Control in expressions_box.get_children():
		child.modulate.a = 1.0 if (child == node) else 0.3
		child.set_selected(false)
	node.size.x = 32
	
	expression_string_edit.hide()
	selected_expression_item = null


func _on_expression_move_ended(node: Control):
	for child in expressions_box.get_children():
		child.modulate.a = 1.0
		child.set_selected(child == node)
	
	node.expression_item_data[0] = node.position.x / current_pixels_per_second
	_expressions_reorganize()
	
	expression_string_edit.text = node.expression_item_data[1]
	expression_string_edit.show()
	expression_btn_new.hide()
	selected_expression_item = node


func _on_expression_string_edit_text_submitted(new_text: String) -> void:
	if not selected_expression_item:
		return
	
	selected_expression_item.expression_item_data[1] = new_text
	selected_expression_item.set_expression(new_text)


func _on_btn_expression_new_pressed() -> void:
	var was_empty: bool = expression_data.size() == 0
	var time_start: float = 0.0 if was_empty else (expression_data[-1][0] + current_audio_length)*0.5
	var new_data: Array = [time_start, "expression_name"]
	expression_data.append(new_data)
	_expression_add_node(new_data, time_start, 0.0, true)
	if not was_empty:
		_expressions_reorganize() # We need to reorganize to fix is_last_item for the old one
	_update_zoom()


func _on_btn_expression_split_pressed() -> void:
	if not selected_expression_item:
		return
	
	var old_time_end: float = selected_expression_item.time_position_end if (not selected_expression_item.is_last_item) else current_audio_length
	var old_duration: float = old_time_end - selected_expression_item.time_position_start
	var new_time_start: float = selected_expression_item.time_position_start + old_duration*0.5
	
	# selected item becomes the RIGHT SIDE
	# so we add a clone before and move this one forward
	
	# Insert into expression_data: (there should be no need to reorganize)
	var data_index: int = expression_data.find(selected_expression_item.expression_item_data)
	if data_index < 0:
		return
	var new_data: Array = selected_expression_item.expression_item_data.duplicate()
	expression_data.insert(data_index, new_data)
	
	# Change current data:
	selected_expression_item.expression_item_data[0] = new_time_start
	selected_expression_item.time_position_start = new_time_start
	# We do not change end time nor is_last_item as this is right side
	
	# Create orresponding node:
	_expression_add_node(new_data, float(new_data[0]), new_time_start, false)
	
	_update_zoom()
	


func _on_btn_expression_delete_pressed() -> void:
	if not selected_expression_item:
		return
	
	expression_data.erase(selected_expression_item.expression_item_data)
	expressions_box.remove_child(selected_expression_item)
	selected_expression_item.queue_free()
	selected_expression_item = null
	_expressions_reorganize()
	
	expression_string_edit.hide()
	expression_btn_new.show()


func _on_btn_cancel_pressed() -> void:
	stop_preview()
	dismissed.emit()


func _on_btn_save_pressed() -> void:
	stop_preview()
	save()
	dismissed.emit()
