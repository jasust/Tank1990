extends Marker2D

@export var totalBullets:int = 0

func shoot(shootArgs: Shoot):
	const BULLET = preload("res://scripts/bullet.tscn")
	var currBullets = get_live_bullets()
	if currBullets < totalBullets:
		var newBullet = BULLET.instantiate()
		newBullet.global_position = global_position
		newBullet.global_rotation = global_rotation
		newBullet.strength = shootArgs.strength
		newBullet.friendly = shootArgs.isFriendly
		newBullet.shooterId = shootArgs.shooterId
		add_child(newBullet)

func get_live_bullets() -> int:
	var liveBullets = 0
	for bullet in get_children():
		if bullet.alive:
			liveBullets += 1
	return liveBullets
