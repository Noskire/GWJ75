extends Node

var game_node

var player
var deaths_position = []

var shadow_offset = Vector2(-18, 21)

var bg_move = true

var default_volumes = [1, 0.4, 0.6]

func _ready():
	update_volume(0, default_volumes[0])
	update_volume(1, default_volumes[1])
	update_volume(2, default_volumes[2])

func update_volume(id, value):
	if value == 0:
		AudioServer.set_bus_mute(id, true)
	else:
		AudioServer.set_bus_mute(id, false)
		AudioServer.set_bus_volume_db(id, linear_to_db(value))
