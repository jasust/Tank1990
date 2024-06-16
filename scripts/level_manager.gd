extends Node2D

const XOFFSET:int = 260
const YOFFSET:int = 40
const LVLHEIGHT:int = 26
const LVLWIDTH:int = 26
const FLCNLAYER1:Array[Vector2i] = [Vector2i(17,25),Vector2i(17,24),Vector2i(17,23),Vector2i(18,23),
									Vector2i(19,23),Vector2i(20,23),Vector2i(20,24),Vector2i(20,25)]

var isReady: bool = false
var isPaused: bool = false
var isAlmostOver: bool = false
var musicPlayback: float = 0.0
var enemiesLeft: int = 20

signal lost_game(isManual:bool)

# Ready up
func _ready():
	Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_HIDDEN)
	ready_screen()

func ready_screen():
	$ReadyPause.visible = true
	$ReadyPause/Label.text = "STAGE %d" % global.playingLevel

func _on_ready_sound_finished():
	isReady = true
	load_level(global.playingLevel)
	$ReadyPause.visible = false
	$BackgroundMusic.play()

# Building level
func load_level(lvl:int) -> void:
	const FALCON = preload("res://scripts/falcon.tscn")
	const SPAWN = preload("res://scripts/spawn_point.tscn")
	
	$LevelNum.text = str(lvl)
	if !global.is_multiplayer():
		$Player1.position.x = 1560
		$Player2.visible = false
		$TileMap.place_cell('p1', Vector2i(39,17), 1)
	else:
		$TileMap.place_cell('p1', Vector2i(36,17), 1)
		$TileMap.place_cell('p2', Vector2i(42,17), 1)
	
	var file = FileAccess.open("res://assets/levels/%d" % lvl, FileAccess.READ)
	var levelSetup:String = file.get_as_text()
	var idx:int = 0
	for i in range(LVLHEIGHT):
		for j in range(LVLWIDTH):
			$TileMap.place_cell(levelSetup[idx], Vector2i(j+6,i))
			idx += 1
		idx += 1
	
	for i in range(3):
		var enemySpawn = SPAWN.instantiate()
		enemySpawn.name = 'EnemySpawn%d' % i
		enemySpawn.id = i
		enemySpawn.position.x = 280+480*i
		enemySpawn.position.y = 60
		add_child(enemySpawn)

	var indx = 0
	for i in global.players:
		spawn_player(i, indx)
		indx += 1
		update_lives(i, indx, 0)
	for i in range(1+2*indx):
		spawn_enemy(3-i)
	
	var falcon = FALCON.instantiate()
	falcon.global_position = Vector2(760, 1020)
	add_child(falcon)
	falcon.game_over.connect(on_game_over)
	falcon.game_over_start.connect(on_game_over_start)

# Game over
func on_game_over(isManual:bool = false):
	Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)
	lost_game.emit(isManual)
	queue_free()
	
func on_game_over_start():
	$BackgroundMusic.volume_db = -7
	$BackgroundMusic.pitch_scale = 2
	$ReadyPause/Label.text = "GAME OVER"
	$ReadyPause.color.a = 0.6
	$ReadyPause.visible = true
	isAlmostOver = true

# Player handling
func on_player_desotryed(mpId:int, entId:int):
	update_lives(mpId, entId, -1)
	if global.players[mpId].lives > -1:
		spawn_player(mpId, entId)
	else:
		for i in global.players:
			if global.players[i].lives >= 0:
				return
		lost_game.emit(false)
		
func spawn_player(mpId:int, playerId:int):
	const PLAYER = preload("res://scripts/player.tscn")
	var player = PLAYER.instantiate().with_params(playerId, global.players[mpId].id, 
												  true, global.players[mpId].boat)
	player.global_position = Vector2(600+playerId*320, 1020)
	# player.name = str(global.players[mpId].id)
	player.currLevel = global.players[mpId].level
	player.isBuff = global.players[mpId].buff
	player.destroyed.connect(on_player_desotryed)
	add_child(player)

func update_lives(mpId:int, plId:int, inc:int):
	global.players[mpId].lives += inc
	get_node('Player%d/Lives' % (plId+1)).text = str(maxi(0, global.players[mpId].lives))

# Enemy handling
func on_enemy_desotryed(_mpId:int, enemyId:int):
	spawn_enemy(enemyId)

func on_spawn_available(spawnPoint):
	spawnPoint.became_available.disconnect(on_spawn_available)
	spawn_enemy(spawnPoint.id)
	
func spawn_enemy(slot:int):
	if !enemiesLeft:
		return

	const ENEMY = preload("res://scripts/enemy.tscn")
	var spawnPoint = get_node('EnemySpawn%d' % (slot % 3))
	if spawnPoint.isAvailable:
		var enemy = ENEMY.instantiate().with_params(enemiesLeft + 1, multiplayer.get_unique_id())
		enemy.type = randi() % 4
		enemy.isBuff = randf() < 0.4
		enemy.currLevel = randi() % 4
		enemy.destroyed.connect(on_enemy_desotryed)
		enemy.spawn_power.connect(spawn_power)
		
		enemiesLeft -= 1
		$TileMap.place_cell('', Vector2i(37+(enemiesLeft%4)*2, 1+(enemiesLeft/4)*2))
		spawnPoint.call_deferred('add_child', enemy)
	else:
		spawnPoint.became_available.connect(on_spawn_available)

# Power Ups
func spawn_power():
	$PowerUpSpawner.spawn_random_power()

func _on_power_up_spawner_child_entered_tree(node):
	if node.has_signal('power_collected'):
		node.power_collected.connect(on_power_collected)

func on_power_collected(powerUp: String, body:Node2D):
	if powerUp == 'shovel':
		if body.isFriendly:
			for block in FLCNLAYER1:
				$TileMap.place_cell('@', block)
				$ShovelTimer.start(17)
		else:
			for block in FLCNLAYER1:
				$TileMap.place_cell('.', block)
	elif powerUp == 'tank':
		if body.isFriendly:
			update_lives(body.multiplayerId, body.myId, 1)
		else:
			pass

func _on_shovel_timer_timeout():
	$ShovelTimer.stop()
	for block in FLCNLAYER1:
		$TileMap.place_cell('#', block)

# Pause screen
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if isPaused or !isReady:
			on_game_over(true)
		elif isReady and !isAlmostOver:
			pause_game.rpc()
	elif event.is_action_pressed("ui_accept"):
		if !isReady and !$ReadySound.playing:
			start_ready_timer.rpc()
		if isPaused:
			unpause_game.rpc()

@rpc("any_peer", "call_local")
func pause_game():
	isPaused = true
	musicPlayback = $BackgroundMusic.get_playback_position()
	$BackgroundMusic.stop()
	$ReadyPause/Label.text = "PAUSE"
	$ReadyPause.color.a = 0.6
	$ReadyPause.visible = true
	set_process(false)
	
@rpc("any_peer", "call_local")
func unpause_game():
	isPaused = false
	$BackgroundMusic.play(musicPlayback)
	$ReadyPause.visible = false
	set_process(true)

@rpc("any_peer", "call_local")	
func start_ready_timer():
	$ReadySound.play()
