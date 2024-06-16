extends TileMap

# Layers:
# 1 - players
# 2 - walls
# 3 - water
# 4 - bullet
# 5 - powerups
# 6 - invisible walls
# 7 - ice
# 8 - bush

func take_damage(shootArgs: Shoot) -> int:
	var res1 = demolish(shootArgs.position1, shootArgs.strength, shootArgs.direction)
	var res2 = demolish(shootArgs.position2, shootArgs.strength, shootArgs.direction)
	return maxi(res1, res2)
	
func demolish(coords: Vector2, strength: int, direction:int) -> int:
	var quadrant: int = get_quadrant(coords)
	var gridPos: Vector2i = local_to_map(coords)
	var block: Vector2i = get_cell_atlas_coords(0, gridPos)
	# Full wall
	if block.y < 0:
		return -1
	if block.y == 0:
		if strength == 1:
			set_cell(0, gridPos, 0, Vector2i(0, block.y + direction))
		else:
			set_cell(0, gridPos, -1)
		return 1
	# Half wall
	if block.y < 5:
		if is_halfwall_hit(block.y, quadrant):
			if strength == 1:
				if direction & 1 == block.y & 1:
					set_cell(0, gridPos, -1)
				else:
					var rq = remaining_quadrant(block.y, quadrant)
					set_cell(0, gridPos, 0, Vector2i(0, 4 + rq))
			else:
				set_cell(0, gridPos, -1)
			return 1
		return -1
	# Quarter wall
	if block.y < 9:
		if quadrant + 4 == block.y:
			set_cell(0, gridPos, -1)
			return 1
		return -1
	# Block
	if block.y == 9:
		if strength > 1:
			set_cell(0, gridPos, -1)
			return 1
		return 0
	# Bush
	if block.y == 12:
		if strength == 3:
			set_cell(0, gridPos, -1)
		return -1
	return -1

func get_quadrant(coords: Vector2) -> int:
	var res = 1
	var xr: float = fmod(coords.x, 40.0)
	var yr: float = fmod(coords.y, 40.0)
	if yr > 20:
		res += 1
	if xr < 20:
		res += 2
	return res

func is_halfwall_hit(wall:int, quadrant:int) -> bool:
	if wall == 1:
		return quadrant == 3 or quadrant == 1
	if wall == 2:
		return quadrant == 1 or quadrant == 2
	if wall == 3:
		return quadrant == 2 or quadrant == 4
	return quadrant == 4 or quadrant == 3
	
func remaining_quadrant(wall: int, quadrant:int) -> int:
	if wall == 1:
		return 4-quadrant
	if wall == 2:
		return 3-quadrant
	if wall == 3:
		return 6-quadrant
	return 7-quadrant

func place_cell(type: String, gridPos: Vector2i, source:int = 0):
	var gridCell: Vector2i = get_tileset_coord(type)
	set_cell(0, gridPos, source, gridCell)

func get_tileset_coord(type: String) -> Vector2i:
	if type == 'wall' or type == '#':
		return Vector2i(0,0)
	elif type == 'block' or type == '@':
		return Vector2i(0,9)
	elif type == 'water' or type == '~':
		return Vector2i(0,10)
	elif type == 'bush' or type == '%':
		return Vector2i(0,12)
	elif type == 'ice' or type == '-':
		return Vector2i(0,13)
	elif type == 'p1':
		return Vector2i(0,4)
	elif type == 'p2':
		return Vector2i(0,5)
	else:
		return Vector2i(-1,-1)
