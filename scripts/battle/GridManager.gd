class_name GridManager
extends Node

@export var logic_layer: TileMapLayer
@export var hide_logic_layer_on_start: bool = true

var tiles: Dictionary = {}

var min_cell: Vector2i
var max_cell: Vector2i
var has_bounds: bool = false

var cell_aliases: Dictionary = {}
var canonical_footprints: Dictionary = {}

func _ready() -> void:
	print("READY GridManager")
	load_grid_from_logic_layer()

	if hide_logic_layer_on_start and logic_layer != null:
		logic_layer.visible = false

func load_grid_from_logic_layer() -> void:
	if logic_layer == null:
		push_error("GridManager: logic_layer n'est pas assigné.")
		return

	cell_aliases.clear()
	canonical_footprints.clear()
	tiles.clear()
	has_bounds = false

	var used_cells := logic_layer.get_used_cells()

	if used_cells.is_empty():
		push_warning("GridManager: aucune cellule peinte dans LogicLayer.")
		return

	for cell: Vector2i in used_cells:
		var tile_height := get_height_from_logic_layer(cell)
		var surface_type := get_surface_type_from_logic_layer(cell)

		var tile_data := BattleTileData.new(
			cell,
			tile_height,
			surface_type,
			true
		)

		tiles[cell] = tile_data
		canonical_footprints[cell] = [cell]
		_update_bounds(cell)

	build_cell_aliases_from_logic_layer()

	print("Grid loaded from LogicLayer. Tiles count: ", tiles.size())
	print("Bounds: min=", min_cell, " max=", max_cell)

func build_cell_aliases_from_logic_layer() -> void:
	if logic_layer == null:
		return

	for cell_variant in tiles.keys():
		var cell: Vector2i = cell_variant as Vector2i
		var cell_tile_data := logic_layer.get_cell_tile_data(cell)

		if cell_tile_data == null:
			continue

		var alias_offset_x := get_custom_int(cell_tile_data, "alias_offset_x", 0)
		var alias_offset_y := get_custom_int(cell_tile_data, "alias_offset_y", 0)

		if alias_offset_x == 0 and alias_offset_y == 0:
			continue

		var alias_cell := cell + Vector2i(alias_offset_x, alias_offset_y)

		add_cell_alias(alias_cell, cell)

func add_cell_alias(alias_cell: Vector2i, canonical_cell: Vector2i) -> void:
	if has_tile(alias_cell):
		push_warning(
			"Alias ignoré : "
			+ str(alias_cell)
			+ " est déjà une vraie case logique."
		)
		return

	if cell_aliases.has(alias_cell):
		var existing: Vector2i = cell_aliases[alias_cell] as Vector2i

		if existing != canonical_cell:
			push_warning(
				"Alias conflictuel : "
				+ str(alias_cell)
				+ " pointe déjà vers "
				+ str(existing)
				+ ", impossible de le faire pointer vers "
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

	print("Alias ajouté : ", alias_cell, " -> ", canonical_cell)

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

func get_custom_int(tile_data: TileData, key: String, default_value: int) -> int:
	var value = tile_data.get_custom_data(key)

	if value == null:
		return default_value

	return int(value)
	
func get_height_from_logic_layer(cell: Vector2i) -> int:
	if logic_layer == null:
		return 0

	var cell_tile_data := logic_layer.get_cell_tile_data(cell)

	if cell_tile_data == null:
		return 0

	var value = cell_tile_data.get_custom_data("height")

	if value == null:
		return 0

	return int(value)

func get_surface_type_from_logic_layer(cell: Vector2i) -> String:
	if logic_layer == null:
		return "flat"

	var cell_tile_data := logic_layer.get_cell_tile_data(cell)

	if cell_tile_data == null:
		return "flat"

	var value = cell_tile_data.get_custom_data("surface_type")

	if value == null:
		return "flat"

	return str(value)

func get_world_position_from_cell(cell: Vector2i) -> Vector2:
	if logic_layer == null:
		return Vector2.ZERO

	var local_pos := logic_layer.map_to_local(cell)
	return logic_layer.to_global(local_pos)

func get_render_z_index(cell: Vector2i, tile_height: int, extra: int = 0) -> int:
	return int((cell.x + cell.y) * 10 + tile_height * 100 + extra)

func has_tile(cell: Vector2i) -> bool:
	return tiles.has(cell)

func get_tile(cell: Vector2i) -> BattleTileData:
	return tiles.get(cell, null)

func is_walkable(cell: Vector2i) -> bool:
	var tile := get_tile(cell)

	if tile == null:
		return false

	return tile.walkable and tile.occupied_by == null

func get_neighbor_cells(cell: Vector2i) -> Array[Vector2i]:
	if logic_layer == null:
		return []

	var canonical_cell := resolve_cell(cell)

	if not has_tile(canonical_cell):
		return []

	var result: Array[Vector2i] = []
	var seen: Dictionary = {}

	var footprint_cells := get_footprint_cells(canonical_cell)

	for footprint_cell: Vector2i in footprint_cells:
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
