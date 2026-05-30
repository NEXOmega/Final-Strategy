class_name PathfindingManager
extends Node

@export var grid_manager: GridManager

func get_movement_result(unit: Unit) -> PathfindingResult:
	var start: Vector2i = unit.grid_position
	var result := PathfindingResult.new(start)

	var queue: Array[Dictionary] = []

	queue.append({
		"cell": start,
		"cost": 0
	})

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()

		var current_cell: Vector2i = current["cell"] as Vector2i
		var current_cost: int = int(current["cost"])

		for next_cell: Vector2i in grid_manager.get_neighbor_cells(current_cell):
			if not can_unit_enter_cell(unit, current_cell, next_cell):
				continue

			var next_cost: int = current_cost + get_movement_cost(unit, current_cell, next_cell)

			if next_cost > unit.current_mp:
				continue

			var previous_best_cost: int = result.get_cost(next_cell)

			if previous_best_cost != -1 and previous_best_cost <= next_cost:
				continue

			result.set_cell_data(next_cell, next_cost, current_cell)

			queue.append({
				"cell": next_cell,
				"cost": next_cost
			})

	return result

func get_reachable_cells(unit: Unit) -> Array[Vector2i]:
	var result := get_movement_result(unit)
	return result.reachable_cells

func get_movement_cost(
	unit: Unit,
	from_cell: Vector2i,
	to_cell: Vector2i
) -> int:
	var to_tile: BattleTileData = grid_manager.get_tile(to_cell)

	if to_tile == null:
		return 999999

	return max(1, to_tile.movement_cost)

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
