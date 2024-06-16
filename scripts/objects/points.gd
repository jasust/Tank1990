extends Control

var score: int = 100
var playerId: int = 1

func _ready():
	$Label.text = str(score)
	global.players[playerId].score += score

func _on_timer_timeout():
	queue_free()
