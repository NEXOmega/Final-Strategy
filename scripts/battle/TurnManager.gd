class_name TurnManager
extends Node

@export var unit_manager: UnitManager
@export var auto_start_battle: bool = true
@export var debug_logs: bool = true

var turn_order: Array[Unit] = []
var active_unit_index: int = -1
var active_unit: Unit = null
var round_number: int = 1

func _ready() -> void:
	if auto_start_battle:
		call_deferred("start_battle")

func start_battle() -> void:
	if unit_manager == null:
		push_error("TurnManager: unit_manager n'est pas assigné.")
		return

	build_turn_order()

	if turn_order.is_empty():
		push_warning("TurnManager: aucune unité dans le turn_order.")
		return

	round_number = 1
	active_unit_index = 0
	start_active_unit_turn()

func build_turn_order() -> void:
	turn_order.clear()

	if unit_manager == null:
		return

	for unit: Unit in unit_manager.units:
		if unit == null:
			continue

		turn_order.append(unit)

	if debug_logs:
		print("TurnManager: ordre de tour = ", _get_turn_order_debug_string())

func start_active_unit_turn() -> void:
	if turn_order.is_empty():
		return

	active_unit = turn_order[active_unit_index]

	if active_unit == null:
		advance_to_next_unit()
		return

	if debug_logs:
		print("")
		print("=== Round ", round_number, " ===")
		print("Tour actif : ", active_unit.unit_name)

	active_unit.start_turn()

func end_active_unit_turn() -> void:
	if active_unit == null:
		return

	active_unit.end_turn()
	advance_to_next_unit()

func advance_to_next_unit() -> void:
	if turn_order.is_empty():
		active_unit = null
		active_unit_index = -1
		return

	active_unit_index += 1

	if active_unit_index >= turn_order.size():
		active_unit_index = 0
		round_number += 1

	start_active_unit_turn()

func is_unit_active(unit: Unit) -> bool:
	return unit != null and unit == active_unit

func get_active_unit() -> Unit:
	return active_unit

func _get_turn_order_debug_string() -> String:
	var names: Array[String] = []

	for unit: Unit in turn_order:
		if unit == null:
			continue

		names.append(unit.unit_name)

	return " -> ".join(names)
