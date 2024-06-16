extends Entity

# Local variables unique to a player
var isBuff: bool = false
var isInvincible: bool = false
var slipperyDist: float = 0.0

#Spawning
func _ready():
	super._ready()
	$Boat.frame = myId

func on_finished_spawning():
	super.on_finished_spawning()
	block_movement = 7*int(!is_me())
	start_invincibility(2.5)

func _update_entity_level_params(level:int):
	$PlayerAnimations.stop()
	$Image.frame = 4*level+myId
	super._update_entity_level_params(level)

# To be moved to parent class
func is_me() -> bool:
	if global.is_multiplayer():
		return $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()
	else:
		return true

# Moving
func _physics_process(delta):
	if block_movement & 3 == 3:
		if rotation < 0 or rotation > 3:
			$Image.flip_h = true
		else:
			$Image.flip_h = false
		return

	var directionX = Input.get_axis("move_left", "move_right")
	var directionY = Input.get_axis("move_up", "move_down")
	
	update_direction(directionX, directionY)
	var new_vel = get_new_velocity(directionX, directionY)
	if !new_vel.is_zero_approx():
		slipperyDist = 0.0
		velocity = new_vel
		$PlayerAnimations.play("walk_%d_%d" % [myId, currLevel])
	elif !velocity.is_zero_approx():
		if $SlipperyComponent.isSlippery and slipperyDist < 4*LATTICE_SIZE:
			slipperyDist += speed * delta
			$PlayerAnimations.play("walk_%d_%d" % [myId, currLevel])
		else:
			slipperyDist = 0.0
			velocity.x = 0
			velocity.y = 0
	move_and_slide()

# Shooting
func _input(event):
	if event.is_action_pressed("shoot") and not block_movement&4:
		shoot.rpc()

func get_strength() -> int:
	if isBuff:
		return 3
	if currLevel == 3:
		return 2
	return 1

# Taking hits
func take_damage(shootArgs: Shoot) -> int:
	if shootArgs.shooterId == multiplayerId:
		return -1
	if isInvincible:
		return -2
	if shootArgs.isFriendly:
		return -1 # TODO: paralyze
	if hasBoat:
		hasBoat = false
		return 0
	if !currLevel:
		death_start()
		return 2
	if isBuff:
		isBuff = false
	currLevel = currLevel - 1
	return 1

# Powerups
func start_invincibility(dur: float):
	isInvincible = true
	$GlobalAnimations.play('inv')
	$Invincibility.visible = true
	$Invincibility/Timer.start(dur)

func _on_timer_timeout():
	isInvincible = false
	$GlobalAnimations.stop()
	$Invincibility.visible = false
	
func level_up(numLevels: int):
	if currLevel == 3:
		isBuff = true
		return
	if numLevels == 1:
		currLevel = currLevel + 1
		return
	currLevel = 3
