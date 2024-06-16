extends Area2D

var isSlippery:bool = false

func _on_body_entered(_body):
	isSlippery = true

func _on_body_exited(_body):
	isSlippery = false
