extends Node2D



func _on_audio_stream_player_lipsync_mouth_shape_changed(mouth_shape: int) -> void:
	var tex: Texture = null
	match mouth_shape:
		0, 1: # Rest / closed
			tex = preload("res://example/assets/2d_figure/mouth_a_x.png")
		2: # Slightly open (e.g. EE sound)
			tex = preload("res://example/assets/2d_figure/mouth_b.png")
		3: # Open (e.g. AE sound)
			tex = preload("res://example/assets/2d_figure/mouth_c.png")
		4: # Wide open
			tex = preload("res://example/assets/2d_figure/mouth_d.png")
		5: # Slightly rounded (e.g. the i in bird)
			tex = preload("res://example/assets/2d_figure/mouth_e.png")
		6: # Puckered lips
			tex = preload("res://example/assets/2d_figure/mouth_f.png")
		7: # Biting lower lip (F sound)
			tex = preload("res://example/assets/2d_figure/mouth_g.png")
		8: # Tongue on top of mouth (L sound)
			tex = preload("res://example/assets/2d_figure/mouth_h.png")
	
	if tex:
		$Character/Mouth.texture = tex


func _on_audio_stream_player_lipsync_expression_changed(expression: String) -> void:
	var body_tex: Texture = null
	var eyes_tex: Texture = null
	
	match expression:
		"body_neutral":
			body_tex = preload("res://example/assets/2d_figure/body_neutral.png")
		"body_arms_up":
			body_tex = preload("res://example/assets/2d_figure/body_arms_up.png")
		"body_palm_up":
			body_tex = preload("res://example/assets/2d_figure/body_palm_up.png")
		"body_pointing":
			body_tex = preload("res://example/assets/2d_figure/body_pointing.png")
		
		"eyes_neutral":
			eyes_tex = preload("res://example/assets/2d_figure/eyes_neutral.png")
		"eyes_angry":
			eyes_tex = preload("res://example/assets/2d_figure/eyes_angry.png")
		"eyes_annoyed":
			eyes_tex = preload("res://example/assets/2d_figure/eyes_annoyed.png")
		"eyes_joy":
			eyes_tex = preload("res://example/assets/2d_figure/eyes_joy.png")
	
	if body_tex:
		$Character/Body.texture = body_tex
	
	if eyes_tex:
		$Character/Eyes.texture = eyes_tex


func _on_btn_audio_3_pressed() -> void:
	$AudioStreamPlayerLipsync.play_lipsync(preload("res://example/assets/voices/audio3.wav-lipsync.tres"))
	$CanvasLayerText/TextPreview.text = "Hey, why did you click that button? Are you trying to make me say stuff?"


func _on_btn_audio_4_pressed() -> void:
	$AudioStreamPlayerLipsync.play_lipsync(preload("res://example/assets/voices/audio4.wav-lipsync.tres"))
	$CanvasLayerText/TextPreview.text = "I like you too, random user!"


func _on_audio_stream_player_lipsync_lipsync_stopped() -> void:
	$CanvasLayerText/TextPreview.text = ""
