extends Control

@onready var gwj = $GWJ
#@onready var texture_rect = $TextureRect
#@onready var baluarte = $Baluarte

@onready var logos = [$GWJ, $TextureRect, $Baluarte]

var tween
var wait_time = 1.0
var fade_in_time = 1.0
var fade_out_time = 0.5
var show_time = 3.0

var menu_path = "res://src/menu/menu.tscn"

func _ready():
	await get_tree().create_timer(wait_time).timeout
	
	if tween:
		tween.kill() # Abort the previous animation.
	tween = create_tween()
	
	for l in logos:
		tween.tween_property(l, "modulate", Color("ffffffff"), fade_in_time)
		tween.tween_property(l, "modulate", Color("ffffffff"), show_time)
		tween.tween_property(l, "modulate", Color("ffffff00"), fade_out_time)
	
	await tween.finished
	get_tree().change_scene_to_file(menu_path)

func _process(_delta):
	if Input.is_action_just_pressed("dash"):
		if tween:
			tween.kill()
		get_tree().change_scene_to_file(menu_path)
