extends Node2D

var level_selection
signal end_sess
const LEVEL = preload("res://scripts/level_manager.tscn")

func _ready():
	global.reset_player_perks()
	level_selection = load("res://scripts/level_selection.tscn").instantiate()
	add_child(level_selection)
	level_selection.start_level.connect(open_level)
	level_selection.end_level.connect(quit_game)
	
func open_level(number:int):
	if global.is_multiplayer():
		open_level_rpc.rpc(number)
	else:
		release_level_selector()
		create_level(number)

@rpc("any_peer", "call_local")
func open_level_rpc(number:int):
	release_level_selector()
	create_level(number)
	
@rpc("any_peer", "call_local")
func create_level_rpc(number:int):
	create_level(number)
	
func create_level(number:int):
	global.playingLevel = number
	var level = LEVEL.instantiate()
	self.add_child(level)
	level.lost_game.connect(quit_game)
	
func release_level_selector():
	level_selection.queue_free()

func quit_game(isManual: bool = true):
	# Going back to main menu/multiplayer menu so i kill the game manager
	if global.is_multiplayer():
		if !isManual:
			pass
		quit_game_rpc.rpc()
	else:
		if global.players.has(1):
			global.players.erase(1)
		if !isManual:
			pass
		get_tree().change_scene_to_file("res://scripts/menu.tscn")
		
@rpc("any_peer", "call_local")
func quit_game_rpc():
	end_sess.emit()
	queue_free()
	
func next_level():
	global.playingLevel = global.playingLevel + 1
	if global.is_multiplayer():
		create_level_rpc.rpc(global.playingLevel)
	else:
		create_level(global.playingLevel)
