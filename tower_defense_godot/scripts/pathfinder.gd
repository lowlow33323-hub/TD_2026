extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1)
]


static func find_path(block_map: Dictionary) -> Array[Vector2i]:
	return find_path_from(Defs.START, block_map)


static func find_path_from(start_cell: Vector2i, block_map: Dictionary) -> Array[Vector2i]:
	if block_map.has(start_cell) or block_map.has(Defs.GOAL):
		return []

	var frontier: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {start_cell: start_cell}

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == Defs.GOAL:
			break
		for dir in DIRECTIONS:
			var next_cell := current + dir
			if not is_inside_grid(next_cell):
				continue
			if block_map.has(next_cell) or came_from.has(next_cell):
				continue
			if is_diagonal_blocked(current, dir, block_map):
				continue
			came_from[next_cell] = current
			frontier.append(next_cell)

	if not came_from.has(Defs.GOAL):
		return []

	var path: Array[Vector2i] = []
	var step := Defs.GOAL
	while step != start_cell:
		path.push_front(step)
		step = came_from[step]
	path.push_front(start_cell)
	return path


static func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < Defs.GRID_W and cell.y >= 0 and cell.y < Defs.GRID_H


static func is_diagonal_blocked(current: Vector2i, dir: Vector2i, block_map: Dictionary) -> bool:
	if dir.x == 0 or dir.y == 0:
		return false
	return block_map.has(current + Vector2i(dir.x, 0)) or block_map.has(current + Vector2i(0, dir.y))
