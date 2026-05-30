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

	var target_unit := unit_manager.get_unit_at_cell(target_cell)

	if not is_valid_target(user, target_unit, target_cell, ability):
		return false

	return true

func use_ability(
	user: Unit,
	ability: AbilityDefinition,
	target_cell: Vector2i
) -> bool:
	if not can_use_ability(user, ability, target_cell):
		print("AbilityResolver: compétence refusée.")
		return false

	var target_unit := unit_manager.get_unit_at_cell(target_cell)

	apply_ability_effect(user, ability, target_unit, target_cell)

	user.consume_action(ability.action_cost)

	if ability.ends_turn_after_use and turn_manager != null:
		turn_manager.end_active_unit_turn()

	return true

func apply_ability_effect(
	user: Unit,
	ability: AbilityDefinition,
	target_unit: Unit,
	target_cell: Vector2i
) -> void:
	match ability.damage_type:
		AbilityEnums.DamageType.HEAL:
			apply_heal(user, ability, target_unit)

		AbilityEnums.DamageType.MAGICAL:
			apply_magical_damage(user, ability, target_unit)

		AbilityEnums.DamageType.TRUE_DAMAGE:
			apply_true_damage(user, ability, target_unit)

		_:
			apply_physical_damage(user, ability, target_unit)

func apply_physical_damage(
	user: Unit,
	ability: AbilityDefinition,
	target: Unit
) -> void:
	if target == null:
		return

	var raw_damage: int = user.get_stat(BattleStats.StatType.ATTACK) + ability.power
	var final_damage: int = max(1, raw_damage - target.get_stat(BattleStats.StatType.DEFENSE))

	print(user.unit_name, " utilise ", ability.display_name, " sur ", target.unit_name, " dégâts=", final_damage)
	target.take_damage(final_damage)

	if unit_manager != null:
		unit_manager.remove_dead_units()

func apply_magical_damage(
	user: Unit,
	ability: AbilityDefinition,
	target: Unit
) -> void:
	if target == null:
		return

	var raw_damage: int = user.get_stat(BattleStats.StatType.MAGIC_ATTACK) + ability.power
	var final_damage: int = max(1, raw_damage - target.get_stat(BattleStats.StatType.MAGIC_DEFENSE))

	print(user.unit_name, " lance ", ability.display_name, " sur ", target.unit_name, " dégâts=", final_damage)
	target.take_damage(final_damage)

	if unit_manager != null:
		unit_manager.remove_dead_units()

func apply_true_damage(
	user: Unit,
	ability: AbilityDefinition,
	target: Unit
) -> void:
	if target == null:
		return

	var final_damage: int = max(1, ability.power)

	print(
		user.unit_name,
		" utilise ",
		ability.display_name,
		" dégâts fixes=",
		final_damage
	)

	target.take_damage(final_damage)

	if unit_manager != null:
		unit_manager.remove_dead_units()

func apply_heal(
	user: Unit,
	ability: AbilityDefinition,
	target: Unit
) -> void:
	if target == null:
		return

	var heal_amount: int = user.get_stat(BattleStats.StatType.MAGIC_ATTACK) + ability.power

	print(
		user.unit_name,
		" soigne ",
		target.unit_name,
		" de ",
		heal_amount
	)

	target.heal(heal_amount)
	
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
