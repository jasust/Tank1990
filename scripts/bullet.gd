extends Area2D

var alive:int = 1
var shooterId: int = 0
var direction: Vector2
var friendly:bool = false

var strength:int = 1
var speed:float = 1000.0

func _ready():
	direction = Vector2.UP.rotated(rotation)
	if strength == 3:
		collision_mask += 128
	
func get_direction() -> int:
	# Clockwise from 1 to 4
	if round(direction.y) == -1:
		return 1
	if round(direction.x) == 1:
		return 2
	if round(direction.y) == 1:
		return 3
	return 4

func _physics_process(delta):
	position += direction * speed * delta * alive

func _on_body_entered(body):
	var result: int = 0
	if body.has_method('take_damage'):
		var shootArgs = Shoot.new()
		shootArgs.strength = strength
		shootArgs.shooterId = shooterId
		shootArgs.isFriendly = friendly
		shootArgs.direction = get_direction()
		shootArgs.position1 = $MarkerLeft.global_position
		shootArgs.position2 = $MarkerRight.global_position
		result = body.take_damage(shootArgs)
		
	# -2 disappear (e.g. falcon dead)
	# -1 pass through
	# 0 explode fully but didn't destroy
	# 1 explode fully did destroy
	# 2 explode without sound (destroy tank?)
	if result < -1:
		queue_free()
		
	if result == -1:
		return
	
	alive = 0
	collision_mask = 0
	collision_layer = 0
	$BulletImage.visible = false
	$Explosion.visible = true
	$Explosion/AnimationPlayer.play('explode')
	if result < 2:
		$Explosion/ExplodeSound.play()

func _on_animation_player_animation_finished(_anim_name):
	queue_free()

func _on_area_entered(_area):
	queue_free()
