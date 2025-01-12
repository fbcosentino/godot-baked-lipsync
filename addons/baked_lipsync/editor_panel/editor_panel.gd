@tool
extends Control

const RES_SUFFIX = "-lipsync.tres"

@export var rhubard_download_windows := "https://github.com/DanielSWolf/rhubarb-lip-sync/releases/download/v1.13.0/Rhubarb-Lip-Sync-1.13.0-Windows.zip"
@export var rhubard_download_linux := "https://github.com/DanielSWolf/rhubarb-lip-sync/releases/download/v1.13.0/Rhubarb-Lip-Sync-1.13.0-Linux.zip"
@export var rhubard_download_macos := "https://github.com/DanielSWolf/rhubarb-lip-sync/releases/download/v1.13.0/Rhubarb-Lip-Sync-1.13.0-macOS.zip"
const download_temp_file := "user://rhubarb_downloaded.zip"

const oven_path := "res://addons/baked_lipsync/oven/"
const rhubarb_path_windows: String = oven_path + "Rhubarb-Lip-Sync-1.13.0-Windows/rhubarb.exe"
const rhubarb_path_linux: String = oven_path + "Rhubarb-Lip-Sync-1.13.0-Linux/rhubarb"
const rhubarb_path_macos: String = oven_path + "Rhubarb-Lip-Sync-1.13.0-macOS/rhubarb"

@onready var filetree := $FileTree

@onready var label_has_lipsync := $BottomPanel/LabelContainsLipsync
@onready var label_has_expression := $BottomPanel/LabelContainsExpression

@onready var lipsync_editor_popup := $LipsyncWindow
@onready var lipsync_editor := $LipsyncWindow/LipsyncEditor

@onready var downloader := $RhubarbDownloader

# Maps full file path
var resource_map := {}

var current_path := "res://"

func _ready():
	var rhubarb_file: String = ""
	match OS.get_name():
		"Windows":
			rhubarb_file = rhubarb_path_windows
		"macOS":
			rhubarb_file = rhubarb_path_macos
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			rhubarb_file = rhubarb_path_linux
		_:
			return false
	
	if not FileAccess.file_exists(rhubarb_file):
		print("DOWNLOADING RHUBARB...")
		var result: bool = await download_rhubarb()
		if result:
			print("    OK!")
		else:
			print("    FAILED TO DOWNLOAD OR EXTRACT RHUBARB!")
	if FileAccess.file_exists(rhubarb_file):
		print("Rhubarb ready!")
	
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


func download_rhubarb() -> bool:
	# There are no emitted signals.
	# Invoke with await and check result, e.g.:
	# var result = await download_rhubarb()
	# if result:
	#     // do stuff
	# else:
	#     // complain about error
	
	downloader.download_file = download_temp_file
	var url := ""
	var gdignore_path := ""
	match OS.get_name():
		"Windows":
			url = rhubard_download_windows
			gdignore_path = rhubarb_path_windows.get_base_dir() + "/.gdignore"
		"macOS":
			url = rhubard_download_macos
			gdignore_path = rhubarb_path_macos.get_base_dir() + "/.gdignore"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			url = rhubard_download_linux
			gdignore_path = rhubarb_path_linux.get_base_dir() + "/.gdignore"
		_:
			return false
	
	if FileAccess.file_exists(download_temp_file):
		DirAccess.remove_absolute(download_temp_file)
	
	var err = downloader.request(url)
	if err != OK:
		return false
	
	print("Downloading file: ", url)
	var req_result = await downloader.request_completed
	if req_result[1] != 200:
		print("ERROR\nResult status: ", req_result[1])
		return false
	
	if FileAccess.file_exists(download_temp_file):
		print("Extracting downloaded file...")
		var reader = ZIPReader.new()
		reader.open(download_temp_file)

		# Destination directory for the extracted files (this folder must exist before extraction).
		# Not all ZIP archives put everything in a single root folder,
		# which means several files/folders may be created in `root_dir` after extraction.
		var root_dir = DirAccess.open(oven_path)

		var files = reader.get_files()
		for file_path in files:
			# If the current entry is a directory.
			if file_path.ends_with("/"):
				root_dir.make_dir_recursive(file_path)
				continue

			# Write file contents, creating folders automatically when needed.
			# Not all ZIP archives are strictly ordered, so we need to do this in case
			# the file entry comes before the folder entry.
			root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
			var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
			var buffer = reader.read_file(file_path)
			file.store_buffer(buffer)
		
		var gdignore_file = FileAccess.open(gdignore_path, FileAccess.WRITE)
		gdignore_file.close()
		
		DirAccess.remove_absolute(download_temp_file)
		return true
	
	else:
		print("There was an error downloading the file.")
		return false
