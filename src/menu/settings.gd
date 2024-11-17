extends Control

@onready var bg = $BG

@onready var master_bar = $Grid/HBox/MasterBar
@onready var music_bar = $Grid/HBox2/MusicBar
@onready var sfx_bar = $Grid/HBox3/SFXBar

@onready var master_label = $Grid/HBox/Label
@onready var music_label = $Grid/HBox2/Label
@onready var sfx_label = $Grid/HBox3/Label

@onready var asp_shoot = $Grid/HBox3/ASPShoot

var menu_path = "res://src/menu/menu.tscn"

func _ready():
	if Global.bg_move:
		bg.material.set_shader_parameter("speed", 3)
	else:
		bg.material.set_shader_parameter("speed", 0)
	
	var value = Global.default_volumes[0]
	update_volume(0, value)
	master_bar.value = value
	master_label.set_text("%3d" % (value * 100))
	
	value = Global.default_volumes[1]
	update_volume(1, value)
	music_bar.value = value
	music_label.set_text("%3d" % (value * 100))
	
	value = Global.default_volumes[2]
	update_volume(2, value)
	sfx_bar.value = value
	sfx_label.set_text("%3d" % (value * 100))

func _on_display_mode_btn_item_selected(index):
	if index == 0:
		# Window Mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		# FullScreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func update_volume(id, value):
	Global.default_volumes[id] = value
	if value == 0:
		AudioServer.set_bus_mute(id, true)
	else:
		AudioServer.set_bus_mute(id, false)
		AudioServer.set_bus_volume_db(id, linear_to_db(value))

func _on_master_bar_value_changed(value):
	update_volume(0, value)
	master_label.set_text("%3d" % (value * 100))

func _on_music_bar_value_changed(value):
	update_volume(1, value)
	music_label.set_text("%3d" % (value * 100))

func _on_sfx_bar_value_changed(value):
	update_volume(2, value)
	sfx_label.set_text("%3d" % (value * 100))
	if not asp_shoot.is_playing():
		asp_shoot.play()

func _on_scroll_button_up():
	if Global.bg_move:
		Global.bg_move = false
		bg.material.set_shader_parameter("speed", 0)
	else:
		Global.bg_move = true
		bg.material.set_shader_parameter("speed", 3)

func _on_menu_button_up():
	get_tree().change_scene_to_file(menu_path)
