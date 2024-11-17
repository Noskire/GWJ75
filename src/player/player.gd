extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var dash = $Dash
@onready var shadow = $Shadow
@onready var gun = $Gun
@onready var gun_2 = $Gun2
@onready var hurt_box = $HurtBox
@onready var health_bar = $HealthBar

@onready var anim = $AnimationPlayer

@onready var asp_dash = $ASPDash
@onready var asp_shoot = $ASPShoot
@onready var asp_slime_munching = $ASPSlimeMunching
@onready var asp_self_shot = $ASPSelfShot

var game

var health = 100.0
var max_health = 100.0
var speed = 600
var normal_speed = 600
var dash_speed = 1200
var damage_rate = 5.0

var shoot_cooldown = 0.3
var shoot_timer = 0.0
var can_shoot = true

var dash_cooldown = 3.0
var dash_duration = 0.3
var dash_timer = 0.0
var can_dash = true
var dashing = false

var time_actual_dupli = 0.0
var time_dupli = 0.05
var time_life_dupli = 0.2

### Upgrades
var upg_health = 0
var upg_speed = 0
var upg_shoot_cd = 0
var upg_dash_cd = 0
var upg_two_hands = false

func _ready():
	set_physics_process(false)
	Global.player = self
	
	game = Global.game_node
	if game == null:
		await get_tree().create_timer(1.0).timeout
		game = Global.game_node
		set_physics_process(true)
	else:
		set_physics_process(true)
	
	asp_slime_munching.play()
	asp_slime_munching.stream_paused = true

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	
	move_and_slide()
	shadow.global_position = sprite.global_position + Global.shadow_offset
	
	look_at(get_global_mouse_position())
	
	if not can_shoot:
		shoot_timer += delta
		if shoot_timer >= shoot_cooldown:
			can_shoot = true
	
	if Input.is_action_pressed("shoot") and can_shoot and not game.wave_state == game.TRANSITIONING:
		asp_shoot.play()
		can_shoot = false
		shoot_timer = 0.0
		gun.shoot()
		if upg_two_hands:
			gun_2.shoot()
	
	if Input.is_action_pressed("dash") and can_dash:
		if not asp_dash.is_playing():
			asp_dash.play()
		speed = dash_speed * (1 + 0.1 * upg_speed) # +10% for speed upgrade
		can_dash = false
		dashing = true
		dash_timer = 0.0
	if dashing:
		dash_timer += delta
		if dash_timer >= dash_duration:
			dashing = false
			speed = normal_speed * (1 + 0.1 * upg_speed) # +10% for speed upgrade
			dash_timer = 0.0
		
		time_actual_dupli += delta
		if time_actual_dupli >= time_dupli:
			time_actual_dupli = 0
			new_duplication()
	if not can_dash and not dashing:
		dash_timer += delta
		if dash_timer >= dash_cooldown:
			can_dash = true
	
	var overlapping_mobs = hurt_box.get_overlapping_bodies()
	if overlapping_mobs.size() > 0:
		if not asp_slime_munching.is_playing():
			asp_slime_munching.stream_paused = false
		deplet_health(damage_rate * overlapping_mobs.size() * delta)
	else:
		asp_slime_munching.stream_paused = true

func take_damage(damage):
	if not asp_self_shot.is_playing():
		asp_self_shot.play()
	Signals.self_shot.emit()
	anim.play("hurt")
	deplet_health(damage * damage_rate / 2)

func deplet_health(value):
	health -= value
	health_bar.value = health
	if health <= 0:
		Global.deaths_position.append([position, rotation])
		Signals.health_depleted.emit()

func new_duplication():
	var d = dash.duplicate()
	d.material = dash.material.duplicate()
	d.material.set_shader_parameter("opacity", 0.3)
	d.material.set_shader_parameter("r", 0.2)
	d.material.set_shader_parameter("g", 0.8)
	d.material.set_shader_parameter("b", 0.1)
	d.material.set_shader_parameter("mix_color", 0.7)
	get_parent().add_child(d)
	d.position = global_position
	d.rotation = rotation + deg_to_rad(90)
	await get_tree().create_timer(time_life_dupli).timeout
	d.queue_free()

func upgrade(id):
	match id:
		1: # Health
			upg_health += 1
			max_health += 50
			health += 50
			health_bar.max_value = max_health
		2: # Speed
			upg_speed += 1
			speed = normal_speed * (1 + 0.1 * upg_speed)
		3: # Shoot Cooldown
			upg_shoot_cd += 1
			shoot_cooldown = 0.3 - 0.05 * upg_shoot_cd
		4: # Dash Cooldown
			upg_dash_cd += 1
			dash_cooldown = 3.0 - 0.5 * upg_dash_cd
		5: # Two Hands
			upg_two_hands = true
			gun_2.visible = true
	
	health += max_health / 10.0 #+10% max_health
	if health > max_health:
		health = max_health
	health_bar.value = health

func _on_asp_slime_munching_finished():
	asp_slime_munching.play()
