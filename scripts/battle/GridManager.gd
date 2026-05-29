class_name GridManager
extends Node

const CUSTOM_HEIGHT := "height"
const CUSTOM_SURFACE_TYPE := "surface_type"
const CUSTOM_ALIAS_OFFSET_X := "alias_offset_x"
const CUSTOM_ALIAS_OFFSET_Y := "alias_offset_y"

@export var logic_layer: TileMapLayer
@export var hide_logic_layer_on_start: bool = true
@export var debug_logs: bool = false

var tiles: Dictionary = {}
var cell_aliases: Dictionary = {}
var canonical_footprints: Dictionary = {}

var min_cell: Vector2i
var max_cell: Vector2i
var has_bounds: bool = false

func _ready() -> void:
	load_grid_from_logic_layer()

	if hide_logic_layer_on_start and logic_layer != null:
		logic_layer.visible = false

func load_grid_from_logic_layer() -> void:
	if logic_layer == null:
		push_error("GridManager: logic_layer n'est pas assigné.")
		return

	_clear_grid()

	var used_cells := logic_layer.get_used_cells()

	if used_cells.is_empty():
		push_warning("GridManager: aucune cellule peinte dans LogicLayer.")
		return

	for cell: Vector2i in used_cells:
		_register_logic_cell(cell)

	_build_cell_aliases_from_logic_layer()

	if debug_logs:
		print("Grid loaded. Tiles count=", tiles.size(), " bounds=", min_cell, " -> ", max_cell)

func _clear_grid() -> void:
	tiles.clear()
	cell_aliases.clear()
	canonical_footprints.clear()
	has_bounds = false

func _register_logic_cell(cell: Vector2i) -> void:
	var tile_data_source := _get_logic_tile_data(cell)

	var tile_height := TileCustomDataReader.get_int(tile_data_source, CUSTOM_HEIGHT, 0)
	var surface_type := TileCustomDataReader.get_string(tile_data_source, CUSTOM_SURFACE_TYPE, SurfaceShapeFactory.FLAT)

	var tile_data := BattleTileData.new(cell, tile_height, surface_type, true)

	tiles[cell] = tile_data
	canonical_footprints[cell] = [cell]
	_update_bounds(cell)

func _get_logic_tile_data(cell: Vector2i) -> TileData:
	if logic_layer == null:
		return null

	return logic_layer.get_cell_tile_data(cell)

func _build_cell_aliases_from_logic_layer() -> void:
	for cell_variant in tiles.keys():
		var cell: Vector2i = cell_variant as Vector2i
		var tile_data := _get_logic_tile_data(cell)

		if tile_data == null:
			continue

		var alias_offset := Vector2i(
			TileCustomDataReader.get_int(tile_data, CUSTOM_ALIAS_OFFSET_X, 0),
			TileCustomDataReader.get_int(tile_data, CUSTOM_ALIAS_OFFSET_Y, 0)
		)

		if alias_offset == Vector2i.ZERO:
			continue

		add_cell_alias(cell + alias_offset, cell)

func add_cell_alias(alias_cell: Vector2i, canonical_cell: Vector2i) -> void:
	if has_tile(alias_cell):
		push_warning("GridManager: alias ignoré, la cellule existe déjà: " + str(alias_cell))
		return

	if cell_aliases.has(alias_cell):
		var existing: Vector2i = cell_aliases[alias_cell] as Vector2i

		if existing != canonical_cell:
			push_warning(
				"GridManager: alias conflictuel "
				+ str(alias_cell)
				+ " -> "
				+ str(existing)
				+ ", demandé -> "
				+ str(canonical_cell)
			)

		return

	cell_aliases[alias_cell] = canonical_cell

	if not canonical_footprints.has(canonical_cell):
		canonical_footprints[canonical_cell] = [canonical_cell]

	var footprint: Array = canonical_footprints[canonical_cell]

	if not footprint.has(alias_cell):
		footprint.append(alias_cell)

	canonical_footprints[canonical_cell] = footprint

	if debug_logs:
		print("GridManager: alias ajouté ", alias_cell, " -> ", canonical_cell)

func resolve_cell(cell: Vector2i) -> Vector2i:
	if cell_aliases.has(cell):
		return cell_aliases[cell] as Vector2i

	return cell

func get_footprint_cells(cell: Vector2i) -> Array[Vector2i]:
	var canonical_cell := resolve_cell(cell)
	var result: Array[Vector2i] = []

	if not canonical_footprints.has(canonical_cell):
		if has_tile(canonical_cell):
			result.append(canonical_cell)

		return result

	for footprint_cell in canonical_footprints[canonical_cell]:
		result.append(footprint_cell as Vector2i)

	return result

func get_neighbor_cells(cell: Vector2i) -> Array[Vector2i]:
	if logic_layer == null:
		return []

	var canonical_cell := resolve_cell(cell)

	if not has_tile(canonical_cell):
		return []

	var result: Array[Vector2i] = []
	var seen: Dictionary = {}

	for footprint_cell: Vector2i in get_footprint_cells(canonical_cell):
		for neighbor in logic_layer.get_surrounding_cells(footprint_cell):
			var raw_neighbor: Vector2i = neighbor as Vector2i
			var resolved_neighbor := resolve_cell(raw_neighbor)

			if not has_tile(resolved_neighbor):
				continue

			if resolved_neighbor == canonical_cell:
				continue

			if seen.has(resolved_neighbor):
				continue

			result.append(resolved_neighbor)
			seen[resolved_neighbor] = true

	return result

func get_world_position_from_cell(cell: Vector2i) -> Vector2:
	if logic_layer == null:
		return Vector2.ZERO

	var canonical_cell := resolve_cell(cell)
	var local_pos := logic_layer.map_to_local(canonical_cell)
	return logic_layer.to_global(local_pos)

func get_render_z_index(cell: Vector2i, tile_height: int, extra: int = 0) -> int:
	var canonical_cell := resolve_cell(cell)
	return int((canonical_cell.x + canonical_cell.y) * 10 + tile_height * 100 + extra)

func has_tile(cell: Vector2i) -> bool:
	return tiles.has(resolve_cell(cell))

func get_tile(cell: Vector2i) -> BattleTileData:
	return tiles.get(resolve_cell(cell), null)

func is_walkable(cell: Vector2i) -> bool:
	var tile := get_tile(cell)

	if tile == null:
		return false

	return tile.walkable and tile.occupied_by == null

func _update_bounds(cell: Vector2i) -> void:
	if not has_bounds:
		min_cell = cell
		max_cell = cell
		has_bounds = true
		return

	min_cell.x = min(min_cell.x, cell.x)
	min_cell.y = min(min_cell.y, cell.y)
	max_cell.x = max(max_cell.x, cell.x)
	max_cell.y = max(max_cell.y, cell.y)
