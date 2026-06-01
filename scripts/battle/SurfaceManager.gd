class_name SurfaceManager
extends Node

@export var grid_manager: GridManager
@export var surfaces_root: Node2D
@export var tile_surface_scene: PackedScene

@export var tile_half_width: float = 6.0
@export var tile_half_height: float = 3.0
@export var surface_collision_layer: int = 1
@export var highlight_z_index: int = 4095
@export var debug_logs: bool = false

var active_unit_highlight: Polygon2D = null

var surfaces: Dictionary = {}
var highlight_nodes: Array[Polygon2D] = []
var ability_range_nodes: Array[Polygon2D] = []
var ability_area_nodes: Array[Polygon2D] = []

func _ready() -> void:
	call_deferred("build_surfaces")

func build_surfaces() -> void:
	if not _validate_dependencies():
		return

	clear_surfaces()

	for cell_variant in grid_manager.tiles.keys():
		var cell: Vector2i = cell_variant as Vector2i
		var tile := grid_manager.get_tile(cell)

		if tile == null:
			continue

		var surface := _instantiate_surface()

		if surface == null:
			continue

		_register_surface(cell, tile, surface)

	if debug_logs:
		print("SurfaceManager: surfaces générées=", surfaces.size())

func _validate_dependencies() -> bool:
	if grid_manager == null:
		push_error("SurfaceManager: grid_manager n'est pas assigné.")
		return false

	if surfaces_root == null:
		push_error("SurfaceManager: surfaces_root n'est pas assigné.")
		return false

	if tile_surface_scene == null:
		push_error("SurfaceManager: tile_surface_scene n'est pas assignée.")
		return false

	return true

func _instantiate_surface() -> TileSurface:
	var instance := tile_surface_scene.instantiate()

	if instance == null:
		push_error("SurfaceManager: impossible d'instancier TileSurface.")
		return null

	if not instance is TileSurface:
		push_error(
			"SurfaceManager: la scène assignée n'est pas une TileSurface. Type actuel: "
			+ str(instance.get_class())
		)
		instance.queue_free()
		return null

	return instance as TileSurface

func _register_surface(cell: Vector2i, tile: BattleTileData, surface: TileSurface) -> void:
	surfaces_root.add_child(surface)

	var polygon := SurfaceShapeFactory.get_polygon(
		tile.surface_type,
		tile_half_width,
		tile_half_height
	)
	var z := grid_manager.get_render_z_index(cell, tile.height, 20)

	surface.global_position = grid_manager.get_world_position_from_cell(cell)
	surface.collision_layer = surface_collision_layer
	surface.collision_mask = 0
	surface.setup(tile, polygon, z)

	tile.surface = surface
	surfaces[cell] = surface

	if debug_logs:
		print("Surface créée cell=", cell, " pos=", surface.global_position)

func clear_surfaces() -> void:
	clear_highlights()

	if surfaces_root == null:
		return

	for child: Node in surfaces_root.get_children():
		child.queue_free()

	surfaces.clear()

func get_surface_at_cell(cell: Vector2i) -> TileSurface:
	return surfaces.get(grid_manager.resolve_cell(cell), null)

func get_surface_under_global_position(global_pos: Vector2) -> TileSurface:
	var best_surface: TileSurface = null
	var best_z := -999999999

	for surface_variant in surfaces.values():
		var surface := surface_variant as TileSurface

		if surface == null:
			continue

		if not surface.contains_global_point(global_pos):
			continue

		var tile := grid_manager.get_tile(surface.grid_position)

		if tile == null:
			continue

		var z := grid_manager.get_render_z_index(surface.grid_position, tile.height, 20)

		if z > best_z:
			best_z = z
			best_surface = surface

	if best_surface != null:
		if debug_logs:
			print("Surface trouvée : ", best_surface.grid_position)
	else:
		if debug_logs:
			print("Aucune surface pour global_pos=", global_pos)

	return best_surface

func show_move_cells(cells: Array[Vector2i]) -> void:
	clear_highlights()

	for cell: Vector2i in cells:
		var surface := get_surface_at_cell(cell)

		if surface == null:
			if debug_logs:
				print("Surface manquante pour cell=", cell)
			continue

		_create_highlight_for_surface(surface)

func _create_highlight_for_surface(surface: TileSurface) -> void:
	var polygon := Polygon2D.new()
	surfaces_root.add_child(polygon)

	polygon.polygon = surface.surface_polygon
	polygon.color = Color(0.2, 0.6, 1.0, 0.45)
	polygon.global_position = surface.global_position
	polygon.z_as_relative = false
	polygon.z_index = highlight_z_index

	highlight_nodes.append(polygon)

func clear_highlights() -> void:
	for node: Polygon2D in highlight_nodes:
		if is_instance_valid(node):
			node.queue_free()

	highlight_nodes.clear()

	clear_ability_highlights()

func get_unit_world_position(cell: Vector2i) -> Vector2:
	var tile := grid_manager.get_tile(cell)

	if tile == null:
		return grid_manager.get_world_position_from_cell(cell)

	var base_pos := grid_manager.get_world_position_from_cell(cell)
	var anchor_offset := SurfaceAnchorFactory.get_unit_anchor_offset(
		tile.surface_type,
		tile_half_height
	)

	return base_pos + anchor_offset

func show_active_unit_highlight(cell: Vector2i) -> void:
	clear_active_unit_highlight()

	var surface := get_surface_at_cell(cell)

	if surface == null:
		return

	var polygon := Polygon2D.new()
	surfaces_root.add_child(polygon)

	polygon.polygon = surface.surface_polygon
	polygon.color = Color(1.0, 1.0, 0.2, 0.45)
	polygon.global_position = surface.global_position
	polygon.z_as_relative = false
	polygon.z_index = 4096

	active_unit_highlight = polygon

func clear_active_unit_highlight() -> void:
	if active_unit_highlight != null and is_instance_valid(active_unit_highlight):
		active_unit_highlight.queue_free()

	active_unit_highlight = null

func clear_ability_range_highlights() -> void:
	_clear_polygon_nodes(ability_range_nodes)


func clear_ability_area_highlights() -> void:
	_clear_polygon_nodes(ability_area_nodes)


func clear_ability_highlights() -> void:
	clear_ability_range_highlights()
	clear_ability_area_highlights()


func show_ability_target_cells(cells: Array[Vector2i]) -> void:
	clear_ability_highlights()

	for cell: Vector2i in cells:
		_create_cell_highlight(
			cell,
			Color(1.0, 0.75, 0.1, 0.35),
			4096,
			ability_range_nodes
		)


func show_ability_area_cells(cells: Array[Vector2i]) -> void:
	clear_ability_area_highlights()

	for cell: Vector2i in cells:
		_create_cell_highlight(
			cell,
			Color(1.0, 0.15, 0.1, 0.55),
			4097,
			ability_area_nodes
		)


func _create_cell_highlight(
	cell: Vector2i,
	color: Color,
	z: int,
	target_array: Array[Polygon2D]
) -> void:
	var surface := get_surface_at_cell(cell)

	if surface == null:
		return

	var polygon := Polygon2D.new()
	surfaces_root.add_child(polygon)

	polygon.polygon = surface.surface_polygon
	polygon.color = color
	polygon.global_position = surface.global_position
	polygon.z_as_relative = false
	polygon.z_index = z

	target_array.append(polygon)


func _clear_polygon_nodes(nodes: Array[Polygon2D]) -> void:
	for node: Polygon2D in nodes:
		if is_instance_valid(node):
			node.queue_free()

	nodes.clear()
