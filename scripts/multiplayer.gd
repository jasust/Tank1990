extends Control

const SERVER_NUM = 1042
var peer: ENetMultiplayerPeer
var game_manager: Node2D

func _ready():
	$Buttons/Host.grab_focus()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)

func _on_home_button_pressed():
	exit_game(multiplayer.get_unique_id())
	get_tree().change_scene_to_file("res://scripts/menu.tscn")
	
func peer_connected(id:int):
	if id==1:
		$Info.text = 'You have joined the game'
		$Buttons/Host.disabled = true
		$Buttons/Join.disabled = true
		$Buttons/Host.set_disabled_properties()
		$Buttons/Join.set_disabled_properties()
	else:
		$Info.text = 'Player 2 has joined the game'
		$Buttons/StartGame.disabled = false
		$Buttons/StartGame.set_disabled_properties(false)
		$Buttons/StartGame.grab_focus()
	
func peer_disconnected(id:int):
	global.players.erase(id)
	if id==1:
		$Info.text = 'You are no longer in the game'
		$Buttons/Host.disabled = false
		$Buttons/Joined.disabled = false
		$Buttons/Host.set_disabled_properties(false)
		$Buttons/Join.set_disabled_properties(false)
	else:
		$Info.text = 'Player 2 has left the game'
		$Buttons/StartGame.disabled = true
		$Buttons/StartGame.set_disabled_properties()
		
func connected_to_server():
	send_player_info.rpc_id(1, multiplayer.get_unique_id())

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_filedialog_up_one_level"):
		exit_game(multiplayer.get_unique_id())
		get_tree().change_scene_to_file("res://scripts/menu.tscn")

func _on_host_pressed():
	# Set up connection
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(SERVER_NUM, 2)
	if error != OK:
		$Info.text = "Cannot host: " + str(error)
	else:
		$Info.text = 'You are hosting the server'
		$Buttons/Host.disabled = true
		$Buttons/Join.disabled = true
		$Buttons/Host.set_disabled_properties()
		$Buttons/Join.set_disabled_properties()
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	send_player_info(multiplayer.get_unique_id())

# Remote procedure call
@rpc("any_peer")
func send_player_info(id: int):
	if !global.players.has(id):
		global.players[id] = {
			'id': id,
			'unlockedLevels': global.unlockedLevels,
			'score': 0,
			'lives': 3,
			'level': 0,
			'alive': true,
			'buff': false,
			'boat': false
		}
	if multiplayer.is_server():
		for i in global.players:
			send_player_info.rpc(global.players[i].id)

# Call local - bice pozvan i lokalno
@rpc("any_peer", "call_local")
func start_game():
	game_manager = load("res://scripts/game_manager.tscn").instantiate()
	get_tree().root.add_child(game_manager)
	game_manager.end_sess.connect(make_visible)
	hide()
	set_process_input(false)

func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client('127.0.0.1', SERVER_NUM)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)

func _on_start_game_pressed():
	start_game.rpc()

func exit_game(id:int):
	if global.players.has(id):
		global.players.erase(id)
		peer.disconnect_peer(id)

func make_visible():
	show()
	set_process_input(true)
