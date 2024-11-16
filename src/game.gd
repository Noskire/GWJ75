extends Node2D

@onready var crosshair = $Crosshair

@onready var path_follow = $Path2D/PathFollow2D
@onready var path_follow2 = $Path2D2/PathFollow2D

@onready var spawn_timer = $SpawnTimer

@onready var game_over = $GameOver
@onready var label_kills = $GameOver/ColorRect/VBoxContainer/Kills
@onready var label_shots = $GameOver/ColorRect/VBoxContainer/Shots
@onready var label_shot_yourself = $GameOver/ColorRect/VBoxContainer/ShotYourself

@onready var wave_label = $WavesControl/Label
@onready var anim = $WavesControl/AnimationPlayer

@onready var up_btn_1 = $WavesControl/VBox/Button1
@onready var up_btn_2 = $WavesControl/VBox/Button2
@onready var up_btn_3 = $WavesControl/VBox/Button3
@onready var up_btn_4 = $WavesControl/VBox/Button4
@onready var up_btn_5 = $WavesControl/VBox/Button5

var kills = 0
var shots = 0
var shot_yourself = 0

var num_mobs = 0
var next_boss
var next_boss_range = Vector2(10, 15)

var wave = 0
var wave_num_mobs = 10
var shield_chance = 0.0

enum {TRANSITIONING, CHOOSE_UPGRADE, SHOW_WAVE, WAVING, WAVE_ENDED}
var wave_state = TRANSITIONING

var mob_path = preload("res://src/mob.tscn")
var death_path = preload("res://src/death.tscn")

func _ready():
	Global.game_node = self
	
	Signals.health_depleted.connect(_on_health_depleted)
	Signals.mob_killed.connect(_on_mob_killed)
	Signals.gun_fired.connect(_on_gun_fired)
	Signals.self_shot.connect(_on_self_shot)
	
	next_boss = randi_range(next_boss_range[0], next_boss_range[1])
	
	for p in Global.deaths_position:
		var d = death_path.instantiate()
		add_child(d)
		d.position = p[0]
		d.rotation = p[1]
	
	await get_tree().create_timer(2.0).timeout
	wave_state = SHOW_WAVE

func _physics_process(_delta):
	crosshair.position = get_global_mouse_position()
	
	match wave_state:
		TRANSITIONING:
			pass
		CHOOSE_UPGRADE:
			#anim.play("ClearedWave")
			pass
		SHOW_WAVE:
			wave_label.set_text("Wave %2d" % (wave + 1))
			anim.play("NewWave")
		WAVING:
			if spawn_timer.is_stopped() and kills == wave_num_mobs:
				wave_state = WAVE_ENDED
		WAVE_ENDED:
			wave += 1
			spawn_timer.wait_time = 1.5 - 0.1 * wave
			#spawn_timer.autostart = true
			#spawn_timer.start()
			wave_num_mobs += 10 + 5 * wave
			shield_chance += 0.01
			wave_state = TRANSITIONING
			
			if Global.player.upg_health < 5:
				up_btn_1.disabled = false
			if Global.player.upg_speed < 5:
				up_btn_2.disabled = false
			if Global.player.upg_shoot_cd < 5:
				up_btn_3.disabled = false
			if Global.player.upg_dash_cd < 5:
				up_btn_4.disabled = false
			if not Global.player.upg_two_hands:
				up_btn_5.disabled = false
			anim.play("ClearedWave")

func spam_mob():
	var boss = false
	
	var new_mob = mob_path.instantiate()
	if (randi() % 2) == 0:
		path_follow.progress_ratio = randf()
		new_mob.global_position = path_follow.global_position
	else:
		path_follow2.progress_ratio = randf()
		new_mob.global_position = path_follow2.global_position
	add_child(new_mob)
	
	num_mobs += 1
	if num_mobs >= wave_num_mobs:
		spawn_timer.autostart = false
		spawn_timer.stop()
	
	if num_mobs >= next_boss:
		boss = true
		next_boss += randi_range(next_boss_range[0], next_boss_range[1])
	
	if boss:
		new_mob.set_as_boss()
	else:
		var r = randf()
		if r < shield_chance:
			new_mob.add_shield()

func _on_timer_timeout():
	spam_mob()

func _on_health_depleted():
	label_kills.set_text("You kill " + str(kills) + " mobs.")
	label_shots.set_text("You fired " + str(shots) + " times.")
	label_shot_yourself.set_text("You shot yourself " + str(shot_yourself) + " times.")
	game_over.visible = true
	get_tree().paused = true

func _on_mob_killed():
	kills += 1

func _on_gun_fired():
	shots += 1

func _on_self_shot():
	shot_yourself += 1

func _on_restart_button_up():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_upgrade_btn_click(id):
	if id < 1 or id > 5:
		print("Wrong value")
		return
	
	Global.player.upgrade(id)
	
	up_btn_1.disabled = true
	up_btn_2.disabled = true
	up_btn_3.disabled = true
	up_btn_4.disabled = true
	up_btn_5.disabled = true
	
	anim.play_backwards("ClearedWave")
	await get_tree().create_timer(0.5).timeout
	wave_state = SHOW_WAVE

func _on_animation_finished(anim_name):
	if anim_name == "NewWave":
		wave_state = WAVING
		spawn_timer.autostart = true
		spawn_timer.start()
