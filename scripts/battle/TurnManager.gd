class_name TurnManager
extends Node

signal active_unit_changed(unit: Unit)
signal round_changed(round_number: int)
signal battle_ended(winning_team_id: int)

@export var unit_manager: UnitManager
@export var auto_start_battle: bool = true
@export var debug_logs: bool = true

var turn_order: Array[Unit] = []
var active_unit_index: int = -1
var active_unit: Unit = null

var active_team_id: int = -1
var round_number: int = 1
var battle_started: bool = false

func _ready() -> void:
	if auto_start_battle:
		call_deferred("start_battle")

func start_battle() -> void:
	if unit_manager == null:
		push_error("TurnManager: unit_manager n'est pas assigné.")
		return

	build_turn_order()

	if turn_order.is_empty():
		push_warning("TurnManager: aucun combattant.")
		return

	battle_started = true
	round_number = 1
	active_unit_index = 0

	if debug_logs:
		print("TurnManager: combat démarré.")
		print("TurnManager: ordre = ", get_turn_order_debug_string())

	start_active_unit_turn()

func build_turn_order() -> void:
	turn_order = unit_manager.get_alive_units()

	turn_order.sort_custom(func(a: Unit, b: Unit) -> bool:
		var a_speed: int = a.get_stat(BattleStats.StatType.SPEED)
		var b_speed: int = b.get_stat(BattleStats.StatType.SPEED)

		if a_speed == b_speed:
			return a.unit_name < b.unit_name

		return a_speed > b_speed
	)

func start_active_unit_turn() -> void:
	if turn_order.is_empty():
		return

	active_unit = turn_order[active_unit_index]

	if active_unit == null or active_unit.is_dead():
		advance_to_next_unit()
		return

	active_team_id = active_unit.team_id

	if debug_logs:
		print("")
		print("=== Round ", round_number, " ===")
		print("Unité active : ", active_unit.unit_name, " équipe=", active_unit.team_id)

	active_unit.start_turn()

	active_unit_changed.emit(active_unit)

func end_active_unit_turn() -> void:
	if active_unit == null:
		return

	active_unit.end_turn()
	advance_to_next_unit()

func advance_to_next_unit() -> void:
	if unit_manager != null:
		unit_manager.remove_dead_units()

	if check_battle_end():
		return

	rebuild_turn_order_preserving_next()

	if turn_order.is_empty():
		return

	active_unit_index += 1

	if active_unit_index >= turn_order.size():
		active_unit_index = 0
		round_number += 1
		round_changed.emit(round_number)

	start_active_unit_turn()

func rebuild_turn_order_preserving_next() -> void:
	var previous_active := active_unit

	build_turn_order()

	if turn_order.is_empty():
		active_unit_index = -1
		active_unit = null
		return

	if previous_active == null:
		active_unit_index = clamp(active_unit_index, 0, turn_order.size() - 1)
		return

	var previous_index := turn_order.find(previous_active)

	if previous_index == -1:
		active_unit_index = clamp(active_unit_index - 1, -1, turn_order.size() - 1)
	else:
		active_unit_index = previous_index

func is_unit_active(unit: Unit) -> bool:
	return unit != null and unit == active_unit

func is_team_active(team_id: int) -> bool:
	return team_id == active_team_id

func get_active_unit() -> Unit:
	return active_unit

func check_battle_end() -> bool:
	if unit_manager == null:
		return false

	var alive_teams: Dictionary = {}

	for unit: Unit in unit_manager.get_alive_units():
		alive_teams[unit.team_id] = true

	if alive_teams.size() <= 1:
		var winning_team_id := -1

		for team_id in alive_teams.keys():
			winning_team_id = int(team_id)

		if debug_logs:
			print("Combat terminé. Équipe gagnante : ", winning_team_id)

		battle_ended.emit(winning_team_id)
		return true

	return false

func get_turn_order_debug_string() -> String:
	var parts: Array[String] = []

	for unit: Unit in turn_order:
		if unit == null:
			continue

		parts.append(
			unit.unit_name
			+ "(team="
			+ str(unit.team_id)
			+ ", speed="
			+ str(unit.get_stat(BattleStats.StatType.SPEED))
			+ ")"
		)
	return " -> ".join(parts)
