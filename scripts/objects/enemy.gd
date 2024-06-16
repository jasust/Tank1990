extends Entity

const SHOOTPROB: float = 0.8
const SHOOTTIME: float = 1.2
const MOVETIME: float = 1.7
@onready var POINTS = preload('res://scripts/objects/points.tscn')

signal spawn_power()
signal finished_spawning()

# Local varables unique to the enemy
var type:int = 0:
	set(value):
		type = value
		update_enemy_type_params(value)
var isBuff: bool = false:
	set(value):
		isBuff = value
		if value:
			$Image.frame_coords.x = 0
			$EnemyAnimations.play('walk_%d' % type)

#Spawning
func _ready():
	super._ready()
	currentDirection = 2
	velocity = Vector2.DOWN * speed
	$Image.frame_coords.y = 2*type

func on_finished_spawning():
	super.on_finished_spawning()
	finished_spawning.emit()
	block_movement = 0
	if isBuff:
		$EnemyAnimations.play('walk_%d' % type)
	if is_server():
		var timer := Timer.new()
		timer.wait_time = SHOOTTIME
		timer.timeout.connect(_on_shoot_timer_timeout)
		add_child(timer)
		timer.start()
		
		var moveTimer := Timer.new()
		moveTimer.wait_time = MOVETIME
		moveTimer.timeout.connect(_on_move_timer_timeout)
		add_child(moveTimer)
		moveTimer.start()

func _update_entity_level_params(level:int):
	$Image.frame_coords.x = level*int(!isBuff)
	if !isBuff:
		$EnemyAnimations.play('walk_%d_%d' % [type, level])
	super._update_entity_level_params(level)

func update_enemy_type_params(newType:int):
	$Image.frame_coords.y = 2*newType
	if isBuff:
		$EnemyAnimations.play('walk_%d' % newType)
	else:
		$EnemyAnimations.play('walk_%d_%d' % [newType, currLevel])

# Moving
func _physics_process(_delta):
	if block_movement & 3 == 3:
		if rotation < 0 or rotation > 3:
			$Image.flip_h = true
		else:
			$Image.flip_h = false
		return
	move_and_slide()

func _on_move_timer_timeout():
	if randf() < 0.5:
		if randf() < 0.5:
			update_direction(1,0)
			velocity = Vector2.RIGHT * speed
		else:
			update_direction(-1,0)
			velocity = Vector2.LEFT * speed
	else:
		if randf() < 0.5:
			update_direction(0,-1)
			velocity = Vector2.UP * speed
		else:
			update_direction(0,1)
			velocity = Vector2.DOWN * speed

# Shooting
func get_strength() -> int:
	if type == 3:
		return 2
	return 1

func _on_shoot_timer_timeout():
	if randf() < SHOOTPROB:
		shoot.rpc()

# Taking hits
func take_damage(shootArgs: Shoot) -> int:
	if !shootArgs.isFriendly:
		return -1
	if $Spawn.visible:
		return -1
	if hasBoat:
		hasBoat = false
		return 0
	if isBuff:
		spawn_power.emit()
	if currLevel < 1:
		var points = POINTS.instantiate()
		points.playerId = shootArgs.shooterId
		points.position = position
		points.score = 100*(type+1)
		add_sibling(points)
		death_start()
		return 2
	currLevel = currLevel - 1
	return 1

# Power ups
func level_up(numLevels: int):
	if numLevels > 1:
		type = 3
		return
	if isBuff:
		currLevel = 3
	else:
		isBuff = true
