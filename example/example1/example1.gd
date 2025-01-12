extends Control

@onready var body_anims := $"SubViewportContainer/SubViewport/lipsync-chan_animated/AnimationPlayer"
@onready var face_anims := $SubViewportContainer/SubViewport/AnimationPlayerFace
@onready var face := $"SubViewportContainer/SubViewport/lipsync-chan_animated/Armature/Skeleton3D/Face"

@onready var btns := [
	$BtnAudio1,
	$BtnAudio2,
]



func _ready() -> void:
	$TextPreview.text = ""
	
	# Connect pressed signals from buttons
	for i in range(btns.size()):
		var btn = btns[i]
		btn.pressed.connect(_on_btn_audio.bind(i))
	
	# Set loop here so we don't need to change animation names
	for anim_name in ["idle", "neutral"]:
		body_anims.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	
	# Start with idle pose (T-pose wouldn't be very appealing...)
	body_anims.play("idle")


func _on_audio_stream_player_lipsync_mouth_shape_changed(mouth_shape: int) -> void:
	var blendshape_A := 0.0
	var blendshape_E := 0.0
	var blendshape_I := 0.0
	var blendshape_O := 0.0
	var blendshape_U := 0.0
	
	match mouth_shape:
		0: # Rest position
			pass
		1: # Very closed
			blendshape_O = -0.2
		2: # Slightly open (e.g. EE sound)
			blendshape_E = 0.5
		3: # Open (e.g. AE sound)
			blendshape_A = 0.6
		4: # Wide open
			blendshape_A = 0.7
			blendshape_O = 0.3
		5: # Slightly rounded (e.g. the i in bird)
			blendshape_O = 0.5
			blendshape_U = 0.5
		6: # Puckered lips
			blendshape_U = 1.0
		7: # Biting lower lip (F sound)
			blendshape_E = -0.5
			blendshape_I = 1.0
		8: # Tongue on top of mouth (L sound)
			# The model doesn't move the tongue. We improvise...
			blendshape_E = 0.5
			blendshape_U = 0.5
	
	face.set("blend_shapes/Fcl_MTH_A", blendshape_A)
	face.set("blend_shapes/Fcl_MTH_E", blendshape_E)
	face.set("blend_shapes/Fcl_MTH_I", blendshape_I)
	face.set("blend_shapes/Fcl_MTH_O", blendshape_O)
	face.set("blend_shapes/Fcl_MTH_U", blendshape_U)


func _on_audio_stream_player_lipsync_expression_changed(expression: String) -> void:
	# You can have facial expression animations inside the AnimationPlayer as well
	# (simply by animating the blend shapes)
	# Or you could do them manually via code (just like the mouth shapes) by calling
	# face.set("blend_shapes/<blend shape name>", value)
	# In this example the face blendshapes are on a separate AnimationPlayer
	# for simplicity: this way, face animation can be independent from body without
	# needing to set an AnimationTree
	# (But using an AnimationTree would be the best way in a final game)
	
	# In this example, you're expected to just use animation names as expression names
	
	if expression.begins_with("face_"):
		face_anims.play(expression, 0.5)
	
	else:
		body_anims.play(expression, 0.5)


func _on_btn_audio(index: int):
	match index:
		0:
			$AudioStreamPlayerLipsync.play_lipsync(preload("res://example/assets/voices/audio1.wav-lipsync.tres"))
			$TextPreview.text = "Greetings, soldier! I am Lipsync-chan, the proud mascot of the Baked Lipsync plugin! I... uh... I don't really have any mission to do now, I guess my purpose is just to showcase things."
		1:
			$AudioStreamPlayerLipsync.play_lipsync(preload("res://example/assets/voices/audio2.wav-lipsync.tres"))
			$TextPreview.text = "Hm... Let me think...\nI don't know."


func _on_audio_stream_player_lipsync_lipsync_stopped() -> void:
	$TextPreview.text = ""
