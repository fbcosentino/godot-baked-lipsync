@tool
extends EditorPlugin

var editor_panel: Control

func _enter_tree() -> void:
	add_custom_type(
		"AudioStreamPlayerLipsync", # Name
		"AudioStreamPlayer",        # Parent
		preload("nodes/AudioStreamPlayerLipsync/AudioStreamPlayerLipsync.gd"), # Script
		preload("nodes/AudioStreamPlayerLipsync/AudioStreamPlayerLipsync.png") # Icon
	)
	add_custom_type(
		"AudioStreamPlayerLipsync2D", # Name
		"AudioStreamPlayer2D",        # Parent
		preload("nodes/AudioStreamPlayerLipsync2D/AudioStreamPlayerLipsync2D.gd"), # Script
		preload("nodes/AudioStreamPlayerLipsync2D/AudioStreamPlayerLipsync2D.png") # Icon
	)
	add_custom_type(
		"AudioStreamPlayerLipsync3D", # Name
		"AudioStreamPlayer3D",        # Parent
		preload("nodes/AudioStreamPlayerLipsync3D/AudioStreamPlayerLipsync3D.gd"), # Script
		preload("nodes/AudioStreamPlayerLipsync3D/AudioStreamPlayerLipsync3D.png") # Icon
	)
	
	editor_panel = preload("res://addons/baked_lipsync/editor_panel/editor_panel.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, editor_panel)


func _exit_tree() -> void:
	remove_control_from_docks(editor_panel)
	editor_panel.free()
