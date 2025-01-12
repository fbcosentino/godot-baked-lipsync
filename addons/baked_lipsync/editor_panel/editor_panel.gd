@tool
extends Control

const RES_SUFFIX = "-lipsync.tres"

@onready var filetree := $FileTree

@onready var label_has_lipsync := $BottomPanel/LabelContainsLipsync
@onready var label_has_expression := $BottomPanel/LabelContainsExpression

@onready var lipsync_editor_popup := $LipsyncWindow
@onready var lipsync_editor := $LipsyncWindow/LipsyncEditor

# Maps full file path
var resource_map := {}

var current_path := "res://"

func _ready():
	refresh_file_tree()

# ============================================================================
# RESOURCE CONTENTS

func _get_resource_status(path: String) -> Dictionary:
	# Path is path to the resource file directly, no need to use resource_map
	var result := {
		"lipsync": false,
		"expression": false,
	}
	
	if (not FileAccess.file_exists(path)):
		return result
	
	var res_file: AudioStreamLipsync = load(path)
	if (res_file.lipsync_data.size() > 0):
		result["lipsync"] = true
	if (res_file.expression_data.size() > 0):
		result["expression"] = true
	
	return result


# ============================================================================
# TREE VIEW

func scan_dir_recursive(path: String) -> Array:
	if not path.ends_with("/"):
		path += "/"
	
	var result := []
	
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			var file_path = path + file_name
			if dir.current_is_dir():
				if not file_path in ["res://.godot", "res://addons"]:
					var subdir_content = scan_dir_recursive(path+file_name+"/")
					if subdir_content.size() > 0:
						result.append({
							"type": "dir",
							"name": file_name,
							"path": file_path,
							"content": subdir_content,
						})
			else:
				var ext = file_name.get_extension()
				if ext.to_lower() in ["wav", "ogg"]:
					# Found an audio file
					var res_file_path = file_path + RES_SUFFIX
					if not FileAccess.file_exists(res_file_path):
						res_file_path = ""
					resource_map[file_path] = {
						"type": "pair" if res_file_path != "" else "audio",
						"name": file_name,
						"audio": file_path,
						"res": res_file_path,
					}
					result.append(resource_map[file_path])
				
				# Check for resources without their audio, for alert reasons
				elif file_name.ends_with(RES_SUFFIX):
					var base_audio_file = path + file_name.left( -RES_SUFFIX.length() )
					if not FileAccess.file_exists(base_audio_file):
						resource_map[file_path] = {
							"type": "orphan",
							"name": file_name,
							"audio": "",
							"res": file_path,
						}
						result.append(resource_map[file_path])
						
					
			file_name = dir.get_next()
	
	return result


func _add_level_to_tree(parent: TreeItem, data: Array):
	for item_data in data:
		var new_dir_item: TreeItem = filetree.create_item(parent)
		
		if item_data["type"] == "dir":
			new_dir_item.set_text(0, item_data["name"])
			new_dir_item.set_metadata(0, {})
			_add_level_to_tree(new_dir_item, item_data["content"])
		
		else:
			match item_data["type"]:
				"pair":
					new_dir_item.set_text(0, item_data["name"])
					new_dir_item.set_metadata(0, item_data)
					new_dir_item.set_custom_color(0, Color.CYAN)
					new_dir_item.set_tooltip_text(0, "A lipsync resource is already created for this audio clip")
				"audio":
					new_dir_item.set_text(0, item_data["name"])
					new_dir_item.set_metadata(0, item_data)
					new_dir_item.set_custom_color(0, Color.YELLOW)
					new_dir_item.set_tooltip_text(0, "A lipsync resource was not yet created for this audio clip")
				"orphan":
					new_dir_item.set_text(0, item_data["name"])
					new_dir_item.set_metadata(0, item_data)
					new_dir_item.set_custom_color(0, Color.ORANGE)
					new_dir_item.set_tooltip_text(0, "This is a previously created lipsync resource but the audio file was not found")


func refresh_file_tree(path: String = "res://"):
	resource_map.clear()
	var tree_data = scan_dir_recursive(path)
	
	filetree.clear()
	
	var root: TreeItem = filetree.create_item(null)
	root.set_text(0, path)
	root.set_metadata(0, {})
	_add_level_to_tree(root, tree_data)


func _on_path_edit_text_submitted(new_text: String) -> void:
	current_path = new_text if new_text != "" else "res://"
	refresh_file_tree(current_path)


func _on_btn_refresh_pressed() -> void:
	refresh_file_tree(current_path)


# ============================================================================
# BOTTOM PANEL

func _on_file_tree_item_selected() -> void:
	# Default text in case the call is aborted
	label_has_lipsync.text = "-"
	label_has_expression.text = "-"
	
	var item: TreeItem = filetree.get_selected()
	if item == null:
		return
	
	var data: Dictionary = item.get_metadata(0)
	if data.size() == 0:
		# Directory
		label_has_lipsync.text = "-"
		label_has_expression.text = "-"
		return
	
	if (not "audio" in data) or (not "res" in data):
		return
	
	# Status always have well-formed fields even in data["res"] is invalid
	var status: Dictionary = _get_resource_status(data["res"])
	
	label_has_lipsync.text = "YES" if status["lipsync"] else "NO"
	label_has_expression.text = "YES" if status["expression"] else "NO"


func _on_file_tree_nothing_selected() -> void:
	label_has_lipsync.text = "-"
	label_has_expression.text = "-"


# ============================================================================
# ITEM EDITING

func _on_file_tree_item_activated() -> void:
	var item: TreeItem = filetree.get_selected()
	if item == null:
		return
	
	var data: Dictionary = item.get_metadata(0)
	if data.size() == 0:
		return # silent if double clicked a folder
	
	if (not "audio" in data) or (not "res" in data):
		return
	
	lipsync_editor.load_data(data["audio"], data["res"])
	lipsync_editor_popup.popup()


func _on_lipsync_window_close_requested() -> void:
	lipsync_editor.stop_preview()
	lipsync_editor_popup.hide()


func _on_lipsync_editor_lipsync_data_generated(audio_file: String, res_file: String) -> void:
	refresh_file_tree(current_path)


func _on_lipsync_editor_dismissed() -> void:
	lipsync_editor.stop_preview()
	lipsync_editor_popup.hide()
	refresh_file_tree(current_path)
