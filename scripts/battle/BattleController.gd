class_name BattleController
extends Node

@export var grid_manager: GridManager
@export var surface_manager: SurfaceManager
@export var unit_manager: UnitManager
@export var pathfinding_manager: PathfindingManager

var selected_unit: Unit = null
var reachable_cells: Array[Vector2i] = []

func _ready() -> void:
	print("READY BattleController")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			handle_left_click()

func handle_left_click() -> void:
	if surface_manager == null:
		push_error("BattleController: surface_manager n'est pas assigné.")
		return

	var world_pos: Vector2 = surface_manager.surfaces_root.get_global_mouse_position()
	var surface := surface_manager.get_surface_under_global_position(world_pos)
	
	if surface == null:
		print("Aucune surface cliquée.")
		clear_selection()
		return

	var cell := surface.grid_position
	var tile := grid_manager.get_tile(cell)

	if tile == null:
		clear_selection()
		return

	var unit: Unit = null

	if unit_manager != null:
		unit = unit_manager.get_unit_at_cell(cell)

	print("Case cliquée : ", cell, " hauteur=", tile.height, " surface=", tile.surface_type)

	if unit != null:
		select_unit(unit)
		return

	if selected_unit != null and reachable_cells.has(cell):
		move_selected_unit_to(cell)
		return

	clear_selection()

func select_unit(unit: Unit) -> void:
	selected_unit = unit
	print("Unité sélectionnée : ", unit.unit_name)

	if pathfinding_manager == null:
		push_error("BattleController: pathfinding_manager n'est pas assigné.")
		return

	reachable_cells = pathfinding_manager.get_reachable_cells(unit)

	print("Cases accessibles : ", reachable_cells.size())

	if surface_manager != null:
		surface_manager.show_move_cells(reachable_cells)
	else:
		push_error("BattleController: surface_manager n'est pas assigné.")

func move_selected_unit_to(target_cell: Vector2i) -> void:
	if selected_unit == null:
		return

	if unit_manager == null:
		push_error("BattleController: unit_manager n'est pas assigné.")
		return

	var from_cell := selected_unit.grid_position
	var from_tile := grid_manager.get_tile(from_cell)
	var to_tile := grid_manager.get_tile(target_cell)

	if from_tile == null or to_tile == null:
		return

	from_tile.occupied_by = null
	to_tile.occupied_by = selected_unit

	selected_unit.grid_position = target_cell
	if surface_manager != null:
		selected_unit.global_position = surface_manager.get_unit_world_position(target_cell)
	else:
		selected_unit.global_position = grid_manager.get_world_position_from_cell(target_cell)
	selected_unit.z_index = unit_manager.get_unit_z_index(target_cell, to_tile.height)

	print("Unité déplacée vers : ", target_cell)

	clear_selection()

func clear_selection() -> void:
	selected_unit = null
	reachable_cells.clear()

	if surface_manager != null:
		surface_manager.clear_highlights()
