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
var input_mode: BattleInputMode = BattleInputMode.NONE
var selected_ability: AbilityDefinition = null

@export var ability_resolver: AbilityResolver

@export var turn_label: Label
@export var action_menu: BattleActionMenu
@export var ability_menu: AbilityMenu

var ability_targetable_cells: Array[Vector2i] = []
var last_ability_preview_cell: Vector2i = Vector2i(999999, 999999)

enum BattleInputMode {
	NONE,
	ACTION_MENU,
	MOVE_TARGETING,
	ABILITY_MENU,
	ABILITY_TARGETING
}

func _ready() -> void:
	print("READY BattleController")

	if turn_manager != null:
		turn_manager.active_unit_changed.connect(_on_active_unit_changed)
		turn_manager.battle_ended.connect(_on_battle_ended)

	if action_menu != null:
		action_menu.move_requested.connect(_on_action_menu_move_requested)
		action_menu.abilities_requested.connect(_on_action_menu_abilities_requested)
		action_menu.wait_requested.connect(_on_action_menu_wait_requested)

	if ability_menu != null:
		ability_menu.ability_selected.connect(_on_ability_selected)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("end_turn"):
		end_turn()
		return

	if event is InputEventMouseMotion:
		if input_mode == BattleInputMode.ABILITY_TARGETING:
			update_ability_preview_under_mouse()
		return

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

	var cell: Vector2i = surface.grid_position
	var tile := grid_manager.get_tile(cell)

	if tile == null:
		clear_selection()
		return

	var unit: Unit = null

	if unit_manager != null:
		unit = unit_manager.get_unit_at_cell(cell)

	print("Case cliquée : ", cell, " hauteur=", tile.height, " surface=", tile.surface_type)

	match input_mode:
		BattleInputMode.NONE:
			if unit != null:
				select_unit(unit)
			return

		BattleInputMode.ACTION_MENU:
			if unit != null:
				select_unit(unit)
			else:
				clear_selection()
			return

		BattleInputMode.MOVE_TARGETING:
			if selected_unit != null and current_movement_result != null and current_movement_result.is_reachable(cell):
				move_selected_unit_to(cell)
			else:
				print("Case non valide pour déplacement.")
			return

		BattleInputMode.ABILITY_MENU:
			if unit != null:
				select_unit(unit)
			return

		BattleInputMode.ABILITY_TARGETING:
			try_use_selected_ability_on_cell(cell)
			return

func try_use_selected_ability_on_cell(target_cell: Vector2i) -> void:
	if selected_unit == null:
		return

	if selected_ability == null:
		print("Aucune compétence sélectionnée.")
		return

	if ability_resolver == null:
		push_error("BattleController: ability_resolver non assigné.")
		return

	var success := ability_resolver.use_ability(
		selected_unit,
		selected_ability,
		target_cell
	)

	if not success:
		print("Cible invalide pour ", selected_ability.display_name)
		return

	clear_selection()
	update_turn_ui()

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
	print("DEBUG select_unit appelé avec ", unit.unit_name)

	if turn_manager != null and not turn_manager.is_unit_active(unit):
		print("Cette unité n'est pas l'unité active : ", unit.unit_name)
		return

	clear_selection(false)

	selected_unit = unit
	input_mode = BattleInputMode.ACTION_MENU

	print(
		"Unité sélectionnée : ",
		unit.unit_name,
		" équipe=",
		unit.team_id,
		" PM=",
		unit.get_stat(BattleStats.StatType.MOVE_POINTS_NOW),
		"/",
		unit.get_stat(BattleStats.StatType.MOVE_POINTS_MAX),
		" Actions=",
		unit.get_stat(BattleStats.StatType.ACTIONS_NOW),
		"/",
		unit.get_stat(BattleStats.StatType.ACTIONS_MAX)
	)

	if action_menu == null:
		push_error("BattleController: action_menu n'est pas assigné.")
		return

	print("DEBUG ouverture du menu action")
	action_menu.open_for_unit(unit)

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

	if movement_cost > selected_unit.get_stat(BattleStats.StatType.MOVE_POINTS_NOW):
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

	selected_unit.consume_move_points(movement_cost)
	selected_unit.mark_moved()
	update_turn_ui()

	print("Unité déplacée vers : ", target_cell)
	print(
		"PM restants : ",
		selected_unit.get_stat(BattleStats.StatType.MOVE_POINTS_NOW),
		"/",
		selected_unit.get_stat(BattleStats.StatType.MOVE_POINTS_MAX)
	)

	if surface_manager != null:
		surface_manager.clear_highlights()

	current_movement_result = null
	reachable_cells.clear()
	input_mode = BattleInputMode.ACTION_MENU

	update_turn_ui()

	if action_menu != null:
		action_menu.open_for_unit(selected_unit)

func clear_selection(close_menus: bool = true) -> void:
	selected_unit = null
	selected_ability = null
	reachable_cells.clear()
	current_movement_result = null
	input_mode = BattleInputMode.NONE
	ability_targetable_cells.clear()
	last_ability_preview_cell = Vector2i(999999, 999999)

	if surface_manager != null:
		surface_manager.clear_highlights()

	if close_menus:
		if action_menu != null:
			action_menu.close()

		if ability_menu != null:
			ability_menu.close()

func _on_action_menu_move_requested() -> void:
	if selected_unit == null:
		return

	if action_menu != null:
		action_menu.close()

	input_mode = BattleInputMode.MOVE_TARGETING

	if pathfinding_manager == null:
		push_error("BattleController: pathfinding_manager n'est pas assigné.")
		return

	current_movement_result = pathfinding_manager.get_movement_result(selected_unit)
	reachable_cells = current_movement_result.reachable_cells

	print("Mode déplacement. Cases accessibles : ", reachable_cells.size())

	if surface_manager != null:
		surface_manager.show_move_cells(reachable_cells)

func _on_action_menu_abilities_requested() -> void:
	if selected_unit == null:
		return

	if action_menu != null:
		action_menu.close()

	input_mode = BattleInputMode.ABILITY_MENU

	if ability_menu != null:
		ability_menu.open_for_unit(selected_unit)

func _on_action_menu_wait_requested() -> void:
	if selected_unit == null:
		return

	if action_menu != null:
		action_menu.close()

	end_turn()

func _on_ability_selected(ability: AbilityDefinition) -> void:
	if selected_unit == null:
		return

	selected_ability = ability
	input_mode = BattleInputMode.ABILITY_TARGETING
	last_ability_preview_cell = Vector2i(999999, 999999)

	if ability_menu != null:
		ability_menu.close()

	if ability_resolver == null:
		push_error("BattleController: ability_resolver non assigné.")
		return

	ability_targetable_cells = ability_resolver.get_targetable_cells(
		selected_unit,
		selected_ability
	)

	print(
		"Compétence sélectionnée : ",
		ability.display_name,
		" portée=",
		ability.min_range,
		"-",
		ability.max_range,
		" cibles possibles=",
		ability_targetable_cells.size()
	)

	if surface_manager != null:
		surface_manager.show_ability_target_cells(ability_targetable_cells)

	update_ability_preview_under_mouse()

func update_ability_preview_under_mouse() -> void:
	if selected_unit == null or selected_ability == null:
		return

	if surface_manager == null or ability_resolver == null:
		return

	var surface := _get_surface_under_mouse()

	if surface == null:
		surface_manager.clear_ability_area_highlights()
		last_ability_preview_cell = Vector2i(999999, 999999)
		return

	var cell: Vector2i = surface.grid_position

	if cell == last_ability_preview_cell:
		return

	last_ability_preview_cell = cell

	if not ability_resolver.can_use_ability(selected_unit, selected_ability, cell):
		surface_manager.clear_ability_area_highlights()
		return

	var affected_cells := ability_resolver.get_affected_cells(
		selected_unit,
		selected_ability,
		cell
	)

	surface_manager.show_ability_area_cells(affected_cells)

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

func _on_active_unit_changed(unit: Unit) -> void:
	clear_selection()

	if surface_manager != null and unit != null:
		surface_manager.show_active_unit_highlight(unit.grid_position)

	print("Nouvelle unité active : ", unit.unit_name)

	update_turn_ui()

func _on_battle_ended(winning_team_id: int) -> void:
	clear_selection()

	if surface_manager != null:
		surface_manager.clear_active_unit_highlight()

	if turn_label != null:
		turn_label.text = "Victoire de l'équipe " + str(winning_team_id)

	print("Victoire de l'équipe ", winning_team_id)

func update_turn_ui() -> void:
	if turn_label == null:
		return

	if turn_manager == null:
		turn_label.text = "No TurnManager"
		return

	var unit := turn_manager.get_active_unit()

	if unit == null:
		turn_label.text = "Aucune unité active"
		return

	turn_label.text = (
		"Round " + str(turn_manager.round_number)
		+ " | "
		+ unit.unit_name
		+ " | Team " + str(unit.team_id)
		+ " | HP " + str(unit.get_stat(BattleStats.StatType.HP_NOW)) + "/" + str(unit.get_stat(BattleStats.StatType.HP_MAX))
		+ " | PM " + str(unit.get_stat(BattleStats.StatType.MOVE_POINTS_NOW)) + "/" + str(unit.get_stat(BattleStats.StatType.MOVE_POINTS_MAX))
		+ " | Actions " + str(unit.get_stat(BattleStats.StatType.ACTIONS_NOW)) + "/" + str(unit.get_stat(BattleStats.StatType.ACTIONS_MAX))
		)
