class_name BattleController
extends Node

@export var grid_manager: GridManager
@export var surface_manager: SurfaceManager
@export var unit_manager: UnitManager
@export var pathfinding_manager: PathfindingManager
@export var debug_logs: bool = false

var selected_unit: Unit = null
var reachable_cells: Array[Vector2i] = []

func _ready() -> void:
	if debug_logs:
		print("READY BattleController")

func _unhandled_input(event: InputEvent) -> void:
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

	if selected_unit != null and reachable_cells.has(cell):
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
	selected_unit = unit

	if debug_logs:
		print("Unité sélectionnée=", unit.unit_name)

	if pathfinding_manager == null:
		push_error("BattleController: pathfinding_manager n'est pas assigné.")
		return

	reachable_cells = pathfinding_manager.get_reachable_cells(unit)

	if debug_logs:
		print("Cases accessibles=", reachable_cells.size())

	surface_manager.show_move_cells(reachable_cells)

func move_selected_unit_to(target_cell: Vector2i) -> void:
	if selected_unit == null:
		return

	var from_cell := selected_unit.grid_position
	var from_tile := grid_manager.get_tile(from_cell)
	var to_tile := grid_manager.get_tile(target_cell)

	if from_tile == null or to_tile == null:
		return

	from_tile.occupied_by = null
	to_tile.occupied_by = selected_unit

	selected_unit.grid_position = target_cell
	selected_unit.global_position = surface_manager.get_unit_world_position(target_cell)
	selected_unit.z_index = unit_manager.get_unit_z_index(target_cell, to_tile.height)

	if debug_logs:
		print("Unité déplacée vers=", target_cell)

	clear_selection()

func clear_selection() -> void:
	selected_unit = null
	reachable_cells.clear()

	if surface_manager != null:
		surface_manager.clear_highlights()

func _clear_selection_with_log(message: String) -> void:
	if debug_logs:
		print(message)

	clear_selection()
