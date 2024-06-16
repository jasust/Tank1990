extends Node2D

func spawn_random_power():
	var type = randi() % 8
	var x_pos = randi() % 10
	var y_pos = randi() % 10
	spawn_power.rpc(type, x_pos, y_pos)

@rpc("call_local","any_peer")
func spawn_power(type, x_pos, y_pos):
	const POWER = preload("res://scripts/power_up.tscn")
	var children = get_children()
	for child in children:
		child.queue_free()
	var power = POWER.instantiate()
	power.type = type
	power.global_position = Vector2(400+x_pos*80, 180+y_pos*80)
	call_deferred('add_child', power)
