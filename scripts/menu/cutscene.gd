extends Node2D

func _ready():
	$EnterMusic.play()

func _on_background_animation_finished():
	get_tree().change_scene_to_file("res://scripts/menu/menu.tscn")

func _on_enter_music_finished():
	$TurnOffTv.play()
