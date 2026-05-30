class_name UnitManager
extends Node

@export var grid_manager: GridManager
@export var units_root: Node2D
@export var unit_scene: PackedScene
@export var surface_manager: SurfaceManager

@export var knight_definition: UnitDefinition
@export var battle_mage_definition: UnitDefinition
@export var goblin_definition: UnitDefinition

var units: Array[Unit] = []

func _ready() -> void:
	print("READY UnitManager")
	call_deferred("spawn_test_units")

func spawn_test_units() -> void:
	spawn_unit_from_definition(knight_definition, 0, Vector2i(4, 28))
	spawn_unit_from_definition(battle_mage_definition, 0, Vector2i(5, 31))
	spawn_unit_from_definition(goblin_definition, 1, Vector2i(6, 30))

func spawn_unit_from_definition(
	definition: UnitDefinition,
	team_id: int,
	grid_position: Vector2i
) -> Unit:
	if definition == null:
		push_error("UnitManager: definition null.")
		return null

	var unit := spawn_unit(definition.display_name, team_id, grid_position)

	if unit == null:
		return null

	unit.apply_definition(definition)
	unit.team_id = team_id

	return unit
	
func spawn_unit(
	unit_name: String,
	team_id: int,
	grid_position: Vector2i
) -> Unit:
	if grid_manager == null:
		push_error("UnitManager: grid_manager n'est pas assigné.")
		return null

	if units_root == null:
		push_error("UnitManager: units_root n'est pas assigné.")
		return null

	if unit_scene == null:
		push_error("UnitManager: unit_scene n'est pas assignée.")
		return null

	if not grid_manager.has_tile(grid_position):
		push_error("UnitManager: aucune case logique à " + str(grid_position))
		return null

	var tile := grid_manager.get_tile(grid_position)

	if tile.occupied_by != null:
		push_error("UnitManager: case déjà occupée " + str(grid_position))
		return null

	var unit := unit_scene.instantiate() as Unit
	units_root.add_child(unit)

	unit.setup(unit_name, team_id, grid_position)

	if surface_manager != null:
		unit.global_position = surface_manager.get_unit_world_position(grid_position)
	else:
		unit.global_position = grid_manager.get_world_position_from_cell(grid_position)
	unit.z_index = get_unit_z_index(grid_position, tile.height)

	tile.occupied_by = unit
	units.append(unit)

	print("Unité créée : ", unit.unit_name, " cellule=", grid_position, " hauteur=", tile.height)

	return unit
	

func reset_all_units_movement_points() -> void:
	for unit: Unit in units:
		if unit == null:
			continue

		unit.set_base_stat(
			BattleStats.StatType.MOVE_POINTS_NOW,
			unit.get_stat(BattleStats.StatType.MOVE_POINTS_MAX)
		)

		print(
			unit.unit_name,
			" PM restaurés : ",
			unit.get_stat(BattleStats.StatType.MOVE_POINTS_NOW),
			"/",
			unit.get_stat(BattleStats.StatType.MOVE_POINTS_MAX)
		)

func get_unit_at_cell(cell: Vector2i) -> Unit:
	var tile := grid_manager.get_tile(cell)

	if tile == null:
		return null

	return tile.occupied_by as Unit

func get_unit_z_index(cell: Vector2i, tile_height: int) -> int:
	return grid_manager.get_render_z_index(cell, tile_height, 50)

func get_alive_units() -> Array[Unit]:
	var result: Array[Unit] = []

	for unit: Unit in units:
		if unit == null:
			continue

		if unit.is_dead():
			continue

		result.append(unit)

	return result

func get_units_by_team(team_id: int) -> Array[Unit]:
	var result: Array[Unit] = []

	for unit: Unit in units:
		if unit == null:
			continue

		if unit.is_dead():
			continue

		if unit.team_id == team_id:
			result.append(unit)

	return result

func remove_dead_units() -> void:
	for unit: Unit in units.duplicate():
		if unit == null:
			continue

		if not unit.is_dead():
			continue

		var tile := grid_manager.get_tile(unit.grid_position)
		if tile != null and tile.occupied_by == unit:
			tile.occupied_by = null

		units.erase(unit)
		unit.queue_free()
