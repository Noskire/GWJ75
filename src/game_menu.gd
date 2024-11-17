extends CanvasLayer

@onready var game_over_label = $"ColorRect/VBoxContainer/GameOver"
@onready var restart = $ColorRect/VBoxContainer/Restart

var paused = false
var game_over = false

func _physics_process(_delta):
	if Input.is_action_just_pressed("pause") and not game_over:
		paused = not paused
		get_tree().paused = paused
		if paused:
			game_over_label.set_text("Paused")
			restart.visible = false
		visible = paused

func call_game_over():
	get_tree().paused = true
	game_over = true
	game_over_label.set_text("Game Over")
	restart.visible = true
	visible = true
