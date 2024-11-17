extends Line2D
class_name Trails

@export var max_length : int = 20

var queue : Array

func _process(_delta):
	var pos = _get_position()
	
	queue.push_front(pos)
	if queue.size() > max_length:
		queue.pop_back()
	
	clear_points()
	for p in queue:
		add_point(p)

func _get_position():
	return get_global_mouse_position()
