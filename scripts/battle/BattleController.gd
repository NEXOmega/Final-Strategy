class_name BattleController
extends Node

@export var grid_manager: GridManager
@export var surface_manager: SurfaceManager
@export var unit_manager: UnitManager
@export var pathfinding_manager: PathfindingManager
@export var turn_manager: TurnManager
@export var debug_logs: bool = false

var selected_unit: Unit = null
var reachable_cells: Array[Vector2i] = []
var current_movement_result: PathfindingResult = null

func _ready() -> void:
	if debug_logs:
		print("READY BattleController")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("end_turn"):
		end_turn()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			handle_left_click()

func handle_left_click() -> void:
	if not _has_required_dependencies():
		return

	var surface := _get_surface_under_mouse()

	if surface == null:
		_clear_selection_with_log("Aucune surface cliquée.")
		return

	var cell := surface.grid_position
	var tile := grid_manager.get_tile(cell)

	if tile == null:
		clear_selection()
		return

	var unit := unit_manager.get_unit_at_cell(cell)

	if debug_logs:
		print("Case cliquée=", cell, " hauteur=", tile.height, " surface=", tile.surface_type)

	if unit != null:
		select_unit(unit)
		return

	if selected_unit != null and current_movement_result != null and current_movement_result.is_reachable(cell):
		move_selected_unit_to(cell)
		return

	clear_selection()

func _has_required_dependencies() -> bool:
	if grid_manager == null:
		push_error("BattleController: grid_manager n'est pas assigné.")
		return false

	if surface_manager == null:
		push_error("BattleController: surface_manager n'est pas assigné.")
		return false

	if unit_manager == null:
		push_error("BattleController: unit_manager n'est pas assigné.")
		return false

	return true

func _get_surface_under_mouse() -> TileSurface:
	var world_pos := surface_manager.surfaces_root.get_global_mouse_position()
	return surface_manager.get_surface_under_global_position(world_pos)

func select_unit(unit: Unit) -> void:
	if turn_manager != null and not turn_manager.is_unit_active(unit):
		print("Cette unité n'est pas l'unité active : ", unit.unit_name)
		return

	selected_unit = unit
	print("Unité sélectionnée : ", unit.unit_name, " PM=", unit.current_mp, "/", unit.max_mp)

	if pathfinding_manager == null:
		push_error("BattleController: pathfinding_manager n'est pas assigné.")
		return

	current_movement_result = pathfinding_manager.get_movement_result(unit)
	reachable_cells = current_movement_result.reachable_cells

	print("Cases accessibles : ", reachable_cells.size())

	if surface_manager != null:
		surface_manager.show_move_cells(reachable_cells)

func move_selected_unit_to(target_cell: Vector2i) -> void:
	if selected_unit == null:
		return

	if unit_manager == null:
		push_error("BattleController: unit_manager n'est pas assigné.")
		return

	if current_movement_result == null:
		push_error("BattleController: aucun résultat de pathfinding actif.")
		return

	var from_cell: Vector2i = selected_unit.grid_position
	var from_tile: BattleTileData = grid_manager.get_tile(from_cell)
	var to_tile: BattleTileData = grid_manager.get_tile(target_cell)

	if from_tile == null or to_tile == null:
		return

	var path := current_movement_result.get_path_to(target_cell)
	var movement_cost := current_movement_result.get_cost(target_cell)

	print("Chemin vers ", target_cell, " coût=", movement_cost, " path=", path)

	if movement_cost < 0:
		push_error("BattleController: coût invalide pour la case " + str(target_cell))
		return

	if movement_cost > selected_unit.current_mp:
		push_error("BattleController: pas assez de PM.")
		return

	from_tile.occupied_by = null
	to_tile.occupied_by = selected_unit

	selected_unit.grid_position = target_cell

	if surface_manager != null:
		selected_unit.global_position = surface_manager.get_unit_world_position(target_cell)
	else:
		selected_unit.global_position = grid_manager.get_world_position_from_cell(target_cell)

	selected_unit.z_index = unit_manager.get_unit_z_index(target_cell, to_tile.height)

	selected_unit.current_mp -= movement_cost
	selected_unit.mark_moved()

	print("Unité déplacée vers : ", target_cell)
	print("PM restants : ", selected_unit.current_mp, "/", selected_unit.max_mp)

	clear_selection()

func clear_selection() -> void:
	selected_unit = null
	reachable_cells.clear()
	current_movement_result = null

	if surface_manager != null:
		surface_manager.clear_highlights()

func _clear_selection_with_log(message: String) -> void:
	if debug_logs:
		print(message)

	clear_selection()

func end_turn() -> void:
	print("Fin du tour demandé")

	clear_selection()

	if turn_manager == null:
		push_error("BattleController: turn_manager n'est pas assigné.")
		return

	turn_manager.end_active_unit_turn()
