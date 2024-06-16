extends Marker2D

signal became_available(spawnPoint:Marker2D)

var id:int = 0
var isAvailable: bool = true

func _on_child_entered_tree(node):
	if node.has_signal('finished_spawning'):
		isAvailable = false
		node.finished_spawning.connect(enemy_spawned)

func enemy_spawned():
	$Timer.start(1)

func _on_timer_timeout():
	$Timer.stop()
	isAvailable = true
	became_available.emit(self)
