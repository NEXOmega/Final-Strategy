class_name AbilityResolver
extends Node

@export var grid_manager: GridManager
@export var unit_manager: UnitManager
@export var turn_manager: TurnManager

func can_use_ability(
	user: Unit,
	ability: AbilityDefinition,
	target_cell: Vector2i
) -> bool:
	if user == null or ability == null:
		return false

	if turn_manager != null and not turn_manager.is_unit_active(user):
		return false

	if not ability.can_pay_cost(user):
		return false

	if not is_cell_in_range(user.grid_position, target_cell, ability.min_range, ability.max_range):
		return false
	if ability.shape == AbilityEnums.AbilityShape.LINE:
		if not is_line_target(user.grid_position, target_cell):
			return false
	
	var target_unit := unit_manager.get_unit_at_cell(target_cell)

	if not is_valid_target(user, target_unit, target_cell, ability):
		return false

	return true

func use_ability(
	user: Unit,
	ability: AbilityDefinition,
	target_cell: Vector2i
) -> bool:
	if not can_select_target_cell(user, ability, target_cell):
		print("AbilityResolver: cible invalide.")
		return false

	var affected_cells: Array[Vector2i] = get_affected_cells(
		user,
		ability,
		target_cell
	)

	for affected_cell: Vector2i in affected_cells:
		process_attack_on_cell(
			user,
			ability,
			target_cell,
			affected_cell
		)

	user.consume_action(ability.action_cost)

	if unit_manager != null:
		unit_manager.remove_dead_units()

	if ability.ends_turn_after_use and turn_manager != null:
		turn_manager.end_active_unit_turn()

	return true

func can_select_target_cell(
	user: Unit,
	ability: AbilityDefinition,
	target_cell: Vector2i
) -> bool:
	if user == null or ability == null:
		return false

	if grid_manager == null:
		return false

	if turn_manager != null and not turn_manager.is_unit_active(user):
		return false

	if not ability.can_pay_cost(user):
		return false

	if not grid_manager.has_tile(target_cell):
		return false

	if not is_cell_in_range(
		user.grid_position,
		target_cell,
		ability.min_range,
		ability.max_range
	):
		return false

	var target_unit: Unit = null

	if unit_manager != null:
		target_unit = unit_manager.get_unit_at_cell(target_cell)

	match ability.target_type:
		AbilityEnums.AbilityTargetType.ENEMY:
			return target_unit != null and user.is_enemy_of(target_unit)

		AbilityEnums.AbilityTargetType.ALLY:
			return target_unit != null and not user.is_enemy_of(target_unit)

		AbilityEnums.AbilityTargetType.SELF:
			return target_unit == user

		AbilityEnums.AbilityTargetType.EMPTY_CELL:
			return target_unit == null

		AbilityEnums.AbilityTargetType.ANY_UNIT:
			return target_unit != null

		AbilityEnums.AbilityTargetType.ANY_CELL:
			return true

		_:
			return false
			
func process_attack_on_cell(
	user: Unit,
	ability: AbilityDefinition,
	target_cell: Vector2i,
	affected_cell: Vector2i
) -> void:
	var attack := BattleAttack.from_ability(
		user,
		ability,
		target_cell,
		affected_cell
	)

	var target_unit: Unit = null

	if unit_manager != null:
		target_unit = unit_manager.get_unit_at_cell(affected_cell)

	if target_unit != null:
		target_unit.process_attack(attack)

	# Plus tard :
	# if object_manager != null:
	#     var objects := object_manager.get_objects_at_cell(affected_cell)
	#     for object in objects:
	#         if object.has_method("process_attack"):
	#             object.process_attack(attack)

func can_affect_unit(
	user: Unit,
	ability: AbilityDefinition,
	target_unit: Unit
) -> bool:
	if user == null or ability == null or target_unit == null:
		return false

	match ability.target_type:
		AbilityEnums.AbilityTargetType.ENEMY:
			return user.is_enemy_of(target_unit)

		AbilityEnums.AbilityTargetType.ALLY:
			return not user.is_enemy_of(target_unit)

		AbilityEnums.AbilityTargetType.SELF:
			return target_unit == user

		AbilityEnums.AbilityTargetType.ANY_UNIT:
			return true

		AbilityEnums.AbilityTargetType.ANY_CELL:
			return true

		AbilityEnums.AbilityTargetType.EMPTY_CELL:
			return true

		_:
			return false
			

func is_valid_target(
	user: Unit,
	target_unit: Unit,
	target_cell: Vector2i,
	ability: AbilityDefinition
) -> bool:
	match ability.target_type:
		AbilityEnums.AbilityTargetType.ENEMY:
			return target_unit != null and user.is_enemy_of(target_unit)

		AbilityEnums.AbilityTargetType.ALLY:
			return target_unit != null and not user.is_enemy_of(target_unit)

		AbilityEnums.AbilityTargetType.SELF:
			return target_unit == user

		AbilityEnums.AbilityTargetType.ANY_UNIT:
			return target_unit != null

		AbilityEnums.AbilityTargetType.EMPTY_CELL:
			return target_unit == null and grid_manager.has_tile(target_cell)

		AbilityEnums.AbilityTargetType.ANY_CELL:
			return grid_manager.has_tile(target_cell)

		_:
			return false

func is_cell_in_range(
	from_cell: Vector2i,
	to_cell: Vector2i,
	min_range: int,
	max_range: int
) -> bool:
	var distance := get_grid_distance(from_cell, to_cell)

	return distance >= min_range and distance <= max_range

func get_grid_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	if from_cell == to_cell:
		return 0

	var visited: Dictionary = {}
	var queue: Array[Dictionary] = []

	queue.append({
		"cell": from_cell,
		"distance": 0
	})

	visited[from_cell] = true

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_cell: Vector2i = current["cell"] as Vector2i
		var current_distance: int = int(current["distance"])

		if current_cell == to_cell:
			return current_distance

		for neighbor: Vector2i in grid_manager.get_neighbor_cells(current_cell):
			if visited.has(neighbor):
				continue

			visited[neighbor] = true

			queue.append({
				"cell": neighbor,
				"distance": current_distance + 1
			})

	return 999999

func get_targetable_cells(
	user: Unit,
	ability: AbilityDefinition
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if user == null or ability == null:
		return result

	if grid_manager == null or unit_manager == null:
		return result

	for cell_variant in grid_manager.tiles.keys():
		var cell: Vector2i = cell_variant as Vector2i

		if can_use_ability(user, ability, cell):
			result.append(cell)

	return result


func get_affected_cells(
	user: Unit,
	ability: AbilityDefinition,
	target_cell: Vector2i
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if user == null or ability == null:
		return result

	if grid_manager == null:
		return result

	target_cell = grid_manager.resolve_cell(target_cell)

	match ability.shape:
		AbilityEnums.AbilityShape.SINGLE:
			_append_unique_cell(result, target_cell)

		AbilityEnums.AbilityShape.DIAMOND:
			result = get_cells_in_distance(target_cell, ability.area_radius)

		AbilityEnums.AbilityShape.CROSS:
			result = get_cross_cells(target_cell, ability.area_radius)

		AbilityEnums.AbilityShape.LINE:
			result = get_line_cells(user.grid_position, target_cell, ability.max_range)

		_:
			_append_unique_cell(result, target_cell)

	return result


func get_cells_in_distance(
	center_cell: Vector2i,
	radius: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if radius <= 0:
		_append_unique_cell(result, center_cell)
		return result

	var visited: Dictionary = {}
	var queue: Array[Dictionary] = []

	queue.append({
		"cell": center_cell,
		"distance": 0
	})

	visited[center_cell] = true

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_cell: Vector2i = current["cell"] as Vector2i
		var current_distance: int = int(current["distance"])

		_append_unique_cell(result, current_cell)

		if current_distance >= radius:
			continue

		for neighbor: Vector2i in grid_manager.get_neighbor_cells(current_cell):
			if visited.has(neighbor):
				continue

			visited[neighbor] = true

			queue.append({
				"cell": neighbor,
				"distance": current_distance + 1
			})

	return result


func get_cross_cells(
	center_cell: Vector2i,
	radius: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	_append_unique_cell(result, center_cell)

	if radius <= 0:
		return result

	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]

	for direction: Vector2i in directions:
		for step in range(1, radius + 1):
			var cell := center_cell + direction * step
			_append_unique_cell(result, cell)

	return result


func get_line_cells(
	from_cell: Vector2i,
	target_cell: Vector2i,
	max_length: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var diff := target_cell - from_cell

	if diff == Vector2i.ZERO:
		return result

	if not is_line_target(from_cell, target_cell):
		_append_unique_cell(result, target_cell)
		return result

	var direction := Vector2i(
		_sign_int(diff.x),
		_sign_int(diff.y)
	)

	for step in range(1, max_length + 1):
		var cell := from_cell + direction * step

		if not grid_manager.has_tile(cell):
			break

		_append_unique_cell(result, cell)

		if cell == target_cell:
			continue

	return result


func is_line_target(from_cell: Vector2i, target_cell: Vector2i) -> bool:
	var diff := target_cell - from_cell

	if diff == Vector2i.ZERO:
		return false

	return (
		diff.x == 0
		or diff.y == 0
		or abs(diff.x) == abs(diff.y)
	)


func _append_unique_cell(cells: Array[Vector2i], cell: Vector2i) -> void:
	if grid_manager == null:
		return

	var resolved_cell := grid_manager.resolve_cell(cell)

	if not grid_manager.has_tile(resolved_cell):
		return

	if cells.has(resolved_cell):
		return

	cells.append(resolved_cell)


func _sign_int(value: int) -> int:
	if value > 0:
		return 1

	if value < 0:
		return -1

	return 0
