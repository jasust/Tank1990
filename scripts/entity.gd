extends CharacterBody2D
class_name Entity

const LATTICE_SIZE = 40.0

signal destroyed(multiplayerId:int, entId:int)

# Local varables describing every entity
var myId:int
var isFriendly:bool
var multiplayerId: int
var speed:float = 200.0
var block_movement: int = 7
# Bitmask: 1 - blocks movement, 2 - blocks rotation, 4 - blocks shooting

# Local variables with custom setters
var currLevel:int = 0:
	set(value):
		currLevel = value
		_update_entity_level_params(value)
var currentDirection:int = 0:
	set(value):
		currentDirection = value
		if value == 0:
			rotation_degrees = 0
			$Image.flip_h = false
		elif value == 1:
			rotation_degrees = 90
			$Image.flip_h = false
		elif value == 2:
			rotation_degrees = 180
			$Image.flip_h = true
		else:
			rotation_degrees = -90
			$Image.flip_h = true
var hasBoat: bool = false:
	set(value):
		hasBoat = value
		$Boat.visible = value
		if value == bool(collision_mask&4):
			collision_mask ^= 4

# Constructor
func with_params(entId:int, multId:int, friendly:bool=false, boat:bool=false) -> Entity:
	myId = entId
	isFriendly = friendly
	multiplayerId = multId
	currentDirection = 2-2*int(isFriendly)
	hasBoat = boat
	return self

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(multiplayerId)
	$Image.visible = false
	$Spawn.visible = true
	$Death.visible = false
	$Invincibility.visible = false
	$GlobalAnimations.play('spawn')

func is_server() -> bool:
	return multiplayerId == 1

# Level managment
func _update_entity_level_params(_value:int):
	$ShootComponent.totalBullets = get_bullets()

func get_bullets() -> int:
	if currLevel < 2:
		return 1
	return 2

func get_strength() -> int:
	return 1

func level_up(_numLevels: int):
	pass

# Spawning
func _on_global_animations_animation_finished(anim_name):
	if anim_name == 'spawn':
		on_finished_spawning()
	if anim_name == 'dead':
		destroyed.emit(multiplayerId, myId)
		queue_free()

func on_finished_spawning():
	$Image.visible = true
	$Spawn.visible = false
	_update_entity_level_params(currLevel)

# Dying
func death_start():
	collision_mask = 0
	collision_layer = 0
	block_movement = 7
	$Death.visible = true
	$GlobalAnimations.play('dead')
	$DeathMusic.play()

# Moving
func get_new_velocity(x:int, y:int) -> Vector2:
	if x:
		return Vector2(x * speed, 0)
	if y:
		return Vector2(0, y * speed)
	return Vector2.ZERO

func update_direction(x:int, y:int) -> bool:
	if x:
		if currentDirection & 1 == 0:
			position.y = round(position.y/LATTICE_SIZE+0.5)*LATTICE_SIZE-LATTICE_SIZE/2
		if x > 0:
			currentDirection = 1
		else:
			currentDirection = 3
		return true
	if y:
		if currentDirection & 1:
			position.x = round(position.x/LATTICE_SIZE)*LATTICE_SIZE
		if y > 0:
			currentDirection = 2
		else:
			currentDirection = 0
		return true
	return false

func dir_to_vec(direction:int) -> Vector2:
	if direction == 1:
		return Vector2.UP
	if direction == 2:
		return Vector2.RIGHT
	if direction == 3:
		return Vector2.DOWN
	return Vector2.LEFT

# Shooting
@rpc("any_peer", "call_local")
func shoot():
	var shootArgs = Shoot.new()
	shootArgs.strength = get_strength()
	shootArgs.shooterId = multiplayerId if isFriendly else myId
	shootArgs.isFriendly = isFriendly
	$ShootComponent.shoot(shootArgs)
