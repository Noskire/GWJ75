extends Node2D

@onready var area = $Area2D
@onready var anim = $AnimationPlayer

enum {CLOSED, OPENING, OPEN, CLOSING}
var state = CLOSED

func _process(_delta):
	if area.has_overlapping_bodies():
		if state == CLOSED or state == CLOSING:
			state = OPENING
			anim.play("open")
		#else: continue playing (do nothing)
	else:
		if state == OPEN or state == OPENING:
			state = CLOSING
			anim.play_backwards("open")
		#else: continue playing backward (do nothing)

func _on_animation_finished(_anim_name):
	if state == OPENING:
		state = OPEN
	elif state == CLOSING:
		state = CLOSED
