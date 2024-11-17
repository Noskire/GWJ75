extends CharacterBody2D

@onready var sprite = $Projectile
@onready var shadow = $Shadow
@onready var trail = $Trail

var initial_speed = 1000
var first_reflection = true
var damage = 1

func _ready():
	trail.gradient = trail.gradient.duplicate()
	#var direction = Vector2(1, 0).rotated(rotation)
	var direction = (get_global_mouse_position() - global_position).normalized()
	velocity = direction * initial_speed

func _physics_process(delta):
	var colision_info = move_and_collide(velocity * delta)
	shadow.global_position = sprite.global_position + Global.shadow_offset / 2
	if colision_info:
		var obj = colision_info.get_collider()
		if obj.has_method("take_damage"):
			obj.take_damage(damage)
			queue_free()
		else:
			velocity = velocity.bounce(colision_info.get_normal())
			if first_reflection:
				damage *= 2
				sprite.modulate = Color("9b1a0a")
				trail.gradient.set_color(0, "9b1a0a") #550f0a
				trail.gradient.set_color(1, "9b1a0a")
				trail.gradient.set_color(2, "9b1a0a00")
				first_reflection = false
		# To get faster
		velocity.x *= 1.1
		velocity.y += 1.1
