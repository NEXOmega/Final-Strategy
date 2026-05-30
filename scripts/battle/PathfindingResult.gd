class_name PathfindingResult
extends RefCounted

var start_cell: Vector2i
var reachable_cells: Array[Vector2i] = []
var costs: Dictionary = {}
var previous_cells: Dictionary = {}

func _init(p_start_cell: Vector2i) -> void:
	start_cell = p_start_cell
	costs[start_cell] = 0

func set_cell_data(
	cell: Vector2i,
	cost: int,
	previous_cell: Vector2i
) -> void:
	costs[cell] = cost
	previous_cells[cell] = previous_cell

	if cell != start_cell and not reachable_cells.has(cell):
		reachable_cells.append(cell)

func is_reachable(cell: Vector2i) -> bool:
	return reachable_cells.has(cell)

func get_cost(cell: Vector2i) -> int:
	if not costs.has(cell):
		return -1

	return int(costs[cell])

func get_path_to(target_cell: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	if target_cell == start_cell:
		path.append(start_cell)
		return path

	if not previous_cells.has(target_cell):
		return path

	var current_cell := target_cell
	path.append(current_cell)

	while current_cell != start_cell:
		if not previous_cells.has(current_cell):
			return []

		current_cell = previous_cells[current_cell] as Vector2i
		path.append(current_cell)

	path.reverse()
	return path
