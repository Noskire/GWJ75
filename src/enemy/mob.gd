extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var shadow = $Shadow
@onready var shield = $Shield
@onready var anim = $AnimationPlayer

var player

var health = 3
var speed = 300

var killed = false
# Avoid getting hit twice at the same time, dying twice
# and emitting the mob_killed signal twice

func _ready():
	sprite.material = sprite.material.duplicate()
	shadow.material = shadow.material.duplicate()
	shield.material = shield.material.duplicate()
	
	player = Global.player
	if player == null:
		await get_tree().create_timer(1.0).timeout
		player = Global.player

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	shadow.global_position = sprite.global_position + Global.shadow_offset
	shield.global_position = sprite.global_position
	
	look_at(player.global_position)

func take_damage(damage):
	if not killed:
		health -= damage
		anim.play("hurt")
		anim.queue("walk")
		
		if shield.visible == true:
			shield.visible = false
		
		if health <= 0:
			killed = true
			set_physics_process(false)
			anim.stop()
			anim.play("die")
			Signals.mob_killed.emit()

func die():
	queue_free()

func set_as_boss():
	health = 5
	speed = 400
	set_modulate_parameters()

func add_shield():
	health = 4
	shield.visible = true

func set_modulate_parameters():
	sprite.material.set_shader_parameter("active", 0.0)
	sprite.material.set_shader_parameter("strength", 0.3)

#func set_dissolve_parameters():
	#sprite.material.set_shader_parameter("active", 1.0)
