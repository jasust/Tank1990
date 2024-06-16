extends Node

var players = {}
var unlockedLevels:int = 0
var playingLevel:int = 0:
	set(value):
		playingLevel = value
		update_unlocked_levels(value)

func _ready():
	load_unlocked_levels()

func load_unlocked_levels():
	var file = FileAccess.open("user://data.txt", FileAccess.READ)
	if file:
		var newValue:int = file.get_8()
		unlockedLevels = newValue
	else:
		update_unlocked_levels(1)

func update_unlocked_levels(newValue:int):
	if newValue > unlockedLevels:
		unlockedLevels = newValue
		var file = FileAccess.open("user://data.txt", FileAccess.WRITE)
		file.store_8(newValue)
		for i in players:
			players[i].unlockedLevels = unlockedLevels 
		
func is_multiplayer() -> bool:
	return players.size() > 1
	
func reset_player_perks():
	if players.is_empty():
		players[1] = {
			'id': 1,
			'unlockedLevels': unlockedLevels,
			'score': 0,
			'lives': 3,
			'level': 0,
			'alive': true,
			'buff': false,
			'boat': false
		}
	else:
		for i in players:
			players[i].unlockedLevels = unlockedLevels 
			players[i].score = 0
			players[i].lives = 3
			players[i].level = 0
			players[i].alive = true
			players[i].boat = false
			players[i].buff = false

