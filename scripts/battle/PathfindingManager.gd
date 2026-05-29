class_name PathfindingManager
extends Node

@export var grid_manager: GridManager

func get_reachable_cells(unit: Unit) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var visited: Dictionary = {}

	var start: Vector2i = unit.grid_position
	var queue: Array[Dictionary] = []

	queue.append({
		"cell": start,
		"cost": 0
	})

	visited[start] = 0

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()

		var current_cell: Vector2i = current["cell"] as Vector2i
		var current_cost: int = int(current["cost"])

		if current_cell != start:
			result.append(current_cell)

		for next_cell: Vector2i in grid_manager.get_neighbor_cells(current_cell):
			if not can_unit_enter_cell(unit, current_cell, next_cell):
				continue

			var next_cost: int = current_cost + 1

			if next_cost > unit.current_mp:
				continue

			if visited.has(next_cell) and int(visited[next_cell]) <= next_cost:
				continue

			visited[next_cell] = next_cost

			queue.append({
				"cell": next_cell,
				"cost": next_cost
			})

	return result

func can_unit_enter_cell(unit: Unit, from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if grid_manager == null:
		return false

	var from_tile: BattleTileData = grid_manager.get_tile(from_cell)
	var to_tile: BattleTileData = grid_manager.get_tile(to_cell)

	if from_tile == null or to_tile == null:
		return false

	if not to_tile.walkable:
		return false

	if to_tile.occupied_by != null:
		return false

	var height_diff: int = to_tile.height - from_tile.height

	if height_diff > unit.jump:
		return false

	if height_diff < -unit.max_fall:
		return false

	return true
