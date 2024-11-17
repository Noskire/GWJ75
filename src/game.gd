extends Node2D

@onready var high_score_label = $CanvasLayer/HighScore

@onready var health_sphere = $CanvasLayer/Health
@onready var dash = $CanvasLayer/Dash
@onready var crosshair = $Crosshair

@onready var path_follow = $Path2D/PathFollow2D
@onready var path_follow2 = $Path2D2/PathFollow2D

@onready var spawn_timer = $SpawnTimer
@onready var game_over = $GameOver
@onready var label_best_score = $GameOver/ColorRect/VBoxContainer/HighScore
@onready var label_survive = $GameOver/ColorRect/VBoxContainer/Survive
@onready var label_kills = $GameOver/ColorRect/VBoxContainer/Kills
@onready var label_shots = $GameOver/ColorRect/VBoxContainer/Shots
@onready var label_shot_yourself = $GameOver/ColorRect/VBoxContainer/ShotYourself

@onready var wave_label = $WavesControl/Label
@onready var anim = $WavesControl/AnimationPlayer

@onready var progress_bar_1 = $WavesControl/VBoxTexture/TextureProgressBar
@onready var progress_bar_2 = $WavesControl/VBoxTexture/TextureProgressBar2
@onready var progress_bar_3 = $WavesControl/VBoxTexture/TextureProgressBar3
@onready var progress_bar_4 = $WavesControl/VBoxTexture/TextureProgressBar4
@onready var progress_bar_5 = $WavesControl/VBoxTexture/TextureProgressBar5

@onready var progress_label_1 = $WavesControl/VBoxLabel/Label
@onready var progress_label_2 = $WavesControl/VBoxLabel/Label2
@onready var progress_label_3 = $WavesControl/VBoxLabel/Label3
@onready var progress_label_4 = $WavesControl/VBoxLabel/Label4
@onready var progress_label_5 = $WavesControl/VBoxLabel/Label5

@onready var upgrade_detail = $WavesControl/UpgradeDetail

@onready var up_btn_1 = $WavesControl/VBox/Button1
@onready var up_btn_2 = $WavesControl/VBox/Button2
@onready var up_btn_3 = $WavesControl/VBox/Button3
@onready var up_btn_4 = $WavesControl/VBox/Button4
@onready var up_btn_5 = $WavesControl/VBox/Button5

var highscore = 0
var total_time = 0

var kills = 0
var shots = 0
var shot_yourself = 0

var num_mobs = 0
var next_boss
var next_boss_range = Vector2(10, 15)

var wave = 0
var max_wave = 11
var wave_num_mobs = 10
var shield_chance = 0.0

enum {TRANSITIONING, CHOOSE_UPGRADE, SHOW_WAVE, WAVING, WAVE_ENDED}
var wave_state = TRANSITIONING

var mob_path = preload("res://src/mob.tscn")
var death_path = preload("res://src/death.tscn")

var menu_path = "res://src/menu.tscn"

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

func _physics_process(delta):
	if wave_state == WAVING:
		total_time += delta
	highscore = int(total_time) * 10 + kills * 500 - shot_yourself * 100
	high_score_label.set_text("%9.0f" % highscore)
	
	health_sphere.material.set_shader_parameter("fV", (Global.player.health / Global.player.max_health))
	if Global.player.can_dash:
		dash.value = 1.0
		dash.modulate.a = 1.0
	else:
		dash.value = (Global.player.dash_timer / Global.player.dash_cooldown)
		dash.modulate.a = 0.75
	crosshair.position = get_global_mouse_position()
	
	match wave_state:
		TRANSITIONING:
			pass
		CHOOSE_UPGRADE:
			#anim.play("ClearedWave")
			pass
		SHOW_WAVE:
			if wave == (max_wave - 1):
				wave_label.set_text("Last Wave!")
			else:
				wave_label.set_text("Wave %2d" % (wave + 1))
			anim.play("NewWave")
		WAVING:
			if spawn_timer.is_stopped() and kills == wave_num_mobs and wave < max_wave:
				wave_state = WAVE_ENDED
		WAVE_ENDED:
			wave += 1
			if wave == max_wave:
				spawn_timer.wait_time = 1.5 - 0.1 * wave
				shield_chance = 1.0
				wave_label.set_text("Survive!")
				anim.play("NewWave")
				wave_state = WAVING
				spawn_timer.autostart = true
				spawn_timer.start()
			else:
				spawn_timer.wait_time = 1.5 - 0.1 * wave
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
	if num_mobs >= wave_num_mobs and wave < max_wave:
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
	label_best_score.set_text("Score: " + str(highscore))
	label_survive.set_text("You survive for " + str(wave) + " waves, " + str(int(total_time)) + " seconds.")
	label_kills.set_text("You killed " + str(kills) + " mobs.")
	label_shots.set_text("You fired " + str(shots) + " times.")
	label_shot_yourself.set_text("You shot yourself " + str(shot_yourself) + " times.")
	game_over.call_game_over()

func _on_mob_killed():
	kills += 1

func _on_gun_fired():
	shots += 1

func _on_self_shot():
	shot_yourself += 1

func _on_upgrade_btn_click(id):
	match id:
		1:
			progress_bar_1.value += 1
			progress_label_1.set_text("%d / %d" % [progress_bar_1.value, progress_bar_1.max_value])
		2:
			progress_bar_2.value += 1
			progress_label_2.set_text("%d / %d" % [progress_bar_2.value, progress_bar_2.max_value])
		3:
			progress_bar_3.value += 1
			progress_label_3.set_text("%d / %d" % [progress_bar_3.value, progress_bar_3.max_value])
		4:
			progress_bar_4.value += 1
			progress_label_4.set_text("%d / %d" % [progress_bar_4.value, progress_bar_4.max_value])
		5:
			progress_bar_5.value += 1
			progress_label_5.set_text("%d / %d" % [progress_bar_5.value, progress_bar_5.max_value])
	
	Global.player.upgrade(id)
	
	up_btn_1.disabled = true
	up_btn_2.disabled = true
	up_btn_3.disabled = true
	up_btn_4.disabled = true
	up_btn_5.disabled = true
	
	anim.play_backwards("ClearedWave")
	await get_tree().create_timer(0.5).timeout
	upgrade_detail.set_text("")
	wave_state = SHOW_WAVE

func _on_upgrade_btn_hover(id):
	var txt = ""
	match id:
		1:
			txt = "[center][font_size=32][b]Health +[/b][/font_size]

+ 50 Health
+ 50 Max Health

Currently %.1f / %.1f

You are healed 1/10 of your max health at the end of each turn.[/center]
" % [Global.player.health, Global.player.max_health]
		2:
			txt = "[center][font_size=32][b]Speed +[/b][/font_size]

+ 1/10 Base Move Speed

Currently %.1f

Your dash speed is doubled.[/center]
" % [Global.player.speed]
		3:
			txt = "[center][font_size=32][b]Rate of Fire +[/b][/font_size]

- 0.05s between each shot

Currently %.2f[/center]
" % [Global.player.shoot_cooldown]
		4:
			txt = "[center][font_size=32][b]Dash Cooldown -[/b][/font_size]

- 0.5s between each dash

Currently %.1f[/center]
" % [Global.player.dash_cooldown]
		5:
			txt = "[center][font_size=32][b]Dual Wield[/b][/font_size]

+ 1 pistol, double the shots![/center]"
	upgrade_detail.set_text(txt)

func _on_upgrade_btn_leave():
	upgrade_detail.set_text("")

func _on_animation_finished(anim_name):
	if anim_name == "NewWave":
		wave_state = WAVING
		spawn_timer.autostart = true
		spawn_timer.start()

func _on_restart_button_up():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_up():
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_path)
