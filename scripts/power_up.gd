extends Area2D

@export var type:int = 0
@onready var POINTS = preload('res://scripts/points.tscn')
# const State = {STATE_IDLE = 0, STATE_JUMP = 5, STATE_SHOOT = 6}

var powerUp: PowerUp
var alive:bool = true
signal power_collected(powerUp:String, body:Node2D)

func _ready():
	var powerUpFactory: PowerUpFactory = PowerUpFactory.new()
	powerUp = powerUpFactory.get_power_up(type)
	$Image/AnimationPlayer.play(powerUp.power)

func _on_body_entered(body: Node2D):
	if !visible:
		return
	var res: bool = powerUp._apply_effect(body)
	if !res:
		power_collected.emit(powerUp.power, body)
	if body.isFriendly:
		var points = POINTS.instantiate()
		points.playerId = body.multiplayerId
		points.position = position
		points.score = 500
		add_sibling(points)
	visible = false
	$PickupSound.play()

class PowerUpFactory:
	func get_power_up(idx: int) -> PowerUp:
		if idx == 0:
			return Bomb.new()
		elif idx == 1:
			return Helmet.new()
		elif idx == 2:
			return Clock.new()
		elif idx == 3:
			return Shovel.new()
		elif idx == 4:
			return Tank.new()
		elif idx == 5:
			return Star.new()
		elif idx == 6:
			return Gun.new()
		return Boat.new()
	
class PowerUp:
	var power: String
	func _apply_effect(_body: Node2D) -> bool:
		return false

class Bomb extends PowerUp:
	func _init():
		power = 'bomb'
	func _apply_effect(_body: Node2D) -> bool:
		return false
		
class Helmet extends PowerUp:
	func _init():
		power = 'helmet'
	func _apply_effect(body: Node2D) -> bool:
		if body.isFriendly:
			body.start_invincibility(10.0)
			return true
		return false

class Clock extends PowerUp:
	func _init():
		power = 'clock'
	func _apply_effect(_body: Node2D) -> bool:
		return false

class Shovel extends PowerUp:
	func _init():
		power = 'shovel'
	func _apply_effect(_body: Node2D) -> bool:
		return false

class Tank extends PowerUp:
	func _init():
		power = 'tank'
	func _apply_effect(_body: Node2D) -> bool:
		return false

class Star extends PowerUp:
	func _init():
		power = 'star'
	func _apply_effect(body: Node2D) -> bool:
		body.level_up(1)
		return true

class Gun extends PowerUp:
	func _init():
		power = 'gun'
	func _apply_effect(body: Node2D) -> bool:
		if body.isFriendly:
			body.level_up(2)
			return true
		return false

class Boat extends PowerUp:
	func _init():
		power = 'boat'
	func _apply_effect(body: Node2D) -> bool:
		body.hasBoat = true
		return true

func _on_audio_stream_player_2d_finished():
	queue_free()
