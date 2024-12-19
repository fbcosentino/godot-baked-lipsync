@tool
class_name RhubarbRunner
extends RefCounted

const _FIXED_ARGS := [
	"-f", "tsv",
	"--machineReadable"
]

@export var rhubarb_path: String = "res://addons/baked_lipsync/oven/rhubarb/rhubarb.exe"
#@export var rhubarb_path: String = "rhubarb.exe"


func invoke(audio_file: String, is_phonetic: bool = false) -> String:
	var rhubarb_abs_path = ProjectSettings.globalize_path(rhubarb_path)
	var audio_abs_path = ProjectSettings.globalize_path(audio_file)
	
	var args := []
	if is_phonetic:
		args.append_array(["-r", "phonetic"])
	args.append_array(_FIXED_ARGS)
	args.append(audio_abs_path)
	
	var output := []
	
	var exec_result = OS.execute(rhubarb_abs_path, args, output, false, true)
	
	if exec_result == -1:
		print("Baked Lipsync error: could not crete process for Rhubarb")
		return ""
	
	if exec_result != 0:
		print("Baked Lipsync error: Rhubarb failed to process the file")
		return ""
	
	return output[0]


func convert_tsv_to_array(tsv: String) -> Array:
	var result := []
	
	var lines = tsv.split("\n")
	for line in lines:
		var items = line.strip_edges().split("\t")
		if items.size() == 2:
			result.append([ float(items[0]), items[1]])
	
	return result
