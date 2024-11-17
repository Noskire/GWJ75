extends Marker2D

@onready var shooting_point = $ShootingPoint
@onready var anim = $AnimationPlayer

var bullet_path = preload("res://src/player/bullet.tscn")

func shoot():
	var new_bullet = bullet_path.instantiate()
	new_bullet.global_position = shooting_point.global_position
	new_bullet.global_rotation = shooting_point.global_rotation
	shooting_point.add_child(new_bullet)
	anim.play("shoot")
	Signals.gun_fired.emit()
