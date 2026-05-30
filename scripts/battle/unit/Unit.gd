class_name Unit
extends Node2D

@export var unit_definition: UnitDefinition

var unit_name: String = "Unit"
var team_id: int = 0
var grid_position: Vector2i = Vector2i.ZERO

var stats: BattleStats = null
var abilities: Array[AbilityDefinition] = []

var has_moved_this_turn: bool = false
var has_acted_this_turn: bool = false
var has_ended_turn: bool = false


func setup(
	p_unit_name: String,
	p_team_id: int,
	p_grid_position: Vector2i
) -> void:
	unit_name = p_unit_name
	team_id = p_team_id
	grid_position = p_grid_position


func apply_definition(definition: UnitDefinition) -> void:
	unit_definition = definition

	if unit_definition == null:
		push_error("Unit: unit_definition null.")
		return

	unit_name = unit_definition.display_name
	stats = unit_definition.build_starting_stats()
	abilities = unit_definition.get_all_abilities()

	if stats == null:
		push_error("Unit: impossible de construire les stats de " + unit_name)
		return

	stats.restore_to_max(BattleStats.StatType.HP_NOW, BattleStats.StatType.HP_MAX)
	stats.restore_to_max(BattleStats.StatType.MOVE_POINTS_NOW, BattleStats.StatType.MOVE_POINTS_MAX)
	stats.restore_to_max(BattleStats.StatType.ACTIONS_NOW, BattleStats.StatType.ACTIONS_MAX)


func start_turn() -> void:
	has_moved_this_turn = false
	has_acted_this_turn = false
	has_ended_turn = false

	if stats == null:
		return

	stats.restore_to_max(BattleStats.StatType.MOVE_POINTS_NOW, BattleStats.StatType.MOVE_POINTS_MAX)
	stats.restore_to_max(BattleStats.StatType.ACTIONS_NOW, BattleStats.StatType.ACTIONS_MAX)

	print(
		unit_name,
		" commence son tour. PM=",
		get_stat(BattleStats.StatType.MOVE_POINTS_NOW),
		"/",
		get_stat(BattleStats.StatType.MOVE_POINTS_MAX),
		" Actions=",
		get_stat(BattleStats.StatType.ACTIONS_NOW),
		"/",
		get_stat(BattleStats.StatType.ACTIONS_MAX)
	)


func end_turn() -> void:
	has_ended_turn = true

	if stats != null:
		stats.set_base(BattleStats.StatType.MOVE_POINTS_NOW, 0)
		stats.set_base(BattleStats.StatType.ACTIONS_NOW, 0)

	print(unit_name, " termine son tour.")


func mark_moved() -> void:
	has_moved_this_turn = true


func can_act() -> bool:
	return get_stat(BattleStats.StatType.ACTIONS_NOW) > 0 and not has_acted_this_turn


func consume_action(amount: int = 1) -> void:
	if stats == null:
		return

	var current_actions: int = get_stat(BattleStats.StatType.ACTIONS_NOW)

	if current_actions <= 0:
		return

	var new_actions: int = int(max(0, current_actions - amount))
	stats.set_base(BattleStats.StatType.ACTIONS_NOW, new_actions)

	has_acted_this_turn = true


func consume_move_points(amount: int) -> void:
	if stats == null:
		return

	var current_move_points: int = get_stat(BattleStats.StatType.MOVE_POINTS_NOW)
	var new_move_points: int = int(max(0, current_move_points - amount))

	stats.set_base(BattleStats.StatType.MOVE_POINTS_NOW, new_move_points)


func take_damage(amount: int) -> void:
	if stats == null:
		return

	var current_hp: int = get_stat(BattleStats.StatType.HP_NOW)
	var new_hp: int = int(max(0, current_hp - amount))

	stats.set_base(BattleStats.StatType.HP_NOW, new_hp)

	print(
		unit_name,
		" subit ",
		amount,
		" dégâts. HP=",
		get_stat(BattleStats.StatType.HP_NOW),
		"/",
		get_stat(BattleStats.StatType.HP_MAX)
	)


func heal(amount: int) -> void:
	if stats == null:
		return

	var current_hp: int = get_stat(BattleStats.StatType.HP_NOW)

	stats.set_base(BattleStats.StatType.HP_NOW, current_hp + amount)
	stats.clamp_current_to_max(BattleStats.StatType.HP_NOW, BattleStats.StatType.HP_MAX)

	print(
		unit_name,
		" récupère ",
		amount,
		" HP. HP=",
		get_stat(BattleStats.StatType.HP_NOW),
		"/",
		get_stat(BattleStats.StatType.HP_MAX)
	)


func is_dead() -> bool:
	return get_stat(BattleStats.StatType.HP_NOW) <= 0


func is_enemy_of(other_unit: Unit) -> bool:
	return other_unit != null and team_id != other_unit.team_id


func get_stat(stat_type: BattleStats.StatType) -> int:
	if stats == null:
		return 0

	return stats.get_stat(stat_type)


func get_base_stat(stat_type: BattleStats.StatType) -> int:
	if stats == null:
		return 0

	return stats.get_base(stat_type)


func set_base_stat(stat_type: BattleStats.StatType, value: int) -> void:
	if stats == null:
		return

	stats.set_base(stat_type, value)


# Alias camelCase si tu préfères :
# unit.getStat(BattleStats.StatType.ATTACK)
func getStat(stat_type: BattleStats.StatType) -> int:
	return get_stat(stat_type)


func getBaseStat(stat_type: BattleStats.StatType) -> int:
	return get_base_stat(stat_type)


func setBaseStat(stat_type: BattleStats.StatType, value: int) -> void:
	set_base_stat(stat_type, value)
