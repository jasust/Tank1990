extends StaticBody2D

signal game_over
signal game_over_start

func take_damage(_shootArgs: Shoot) -> int:
	if $Image.frame == 0:
		game_over_start.emit()
		$Image.frame = 1
		$DeathMusic.play()
		return 2
	return -2

func _on_death_music_finished():
	game_over.emit()
