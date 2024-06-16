extends Control

func _ready():
	$MenuText/MenuItems/Play1.grab_focus()

func _on_play_1_pressed():
	get_tree().change_scene_to_file("res://scripts/level/game_manager.tscn")

func _on_play_2_pressed():
	get_tree().change_scene_to_file("res://scripts/menu/multiplayer.tscn")

func _on_exit_pressed():
	get_tree().quit()
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
