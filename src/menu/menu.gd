extends Control

@onready var bg = $BG

var game_path = "res://src/game.tscn"
var settings_path = "res://src/menu/settings.tscn"

func _ready():
	if Global.bg_move:
		bg.material.set_shader_parameter("speed", 3)
	else:
		bg.material.set_shader_parameter("speed", 0)
	
	await get_tree().create_timer(1.0).timeout
	if not BgMusic.is_playing():
		BgMusic.play()

func _on_play_button_up():
	get_tree().change_scene_to_file(game_path)

func _on_settings_button_up():
	get_tree().change_scene_to_file(settings_path)

func _on_scroll_button_up():
	if Global.bg_move:
		Global.bg_move = false
		bg.material.set_shader_parameter("speed", 0)
	else:
		Global.bg_move = true
		bg.material.set_shader_parameter("speed", 3)
