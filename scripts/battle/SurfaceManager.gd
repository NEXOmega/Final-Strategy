class_name SurfaceManager
extends Node

@export var grid_manager: GridManager
@export var surfaces_root: Node2D
@export var tile_surface_scene: PackedScene

@export var tile_half_width: float = 6.0
@export var tile_half_height: float = 3.0

@export var surface_collision_layer: int = 1

var highlight_nodes: Array[Polygon2D] = []

var surfaces: Dictionary = {}

func _ready() -> void:
	print("READY SurfaceManager")
	call_deferred("build_surfaces")

func build_surfaces() -> void:
	if grid_manager == null:
		push_error("SurfaceManager: grid_manager n'est pas assigné.")
		return

	if surfaces_root == null:
		push_error("SurfaceManager: surfaces_root n'est pas assigné.")
		return

	if tile_surface_scene == null:
		push_error("SurfaceManager: tile_surface_scene n'est pas assignée.")
		return

	clear_surfaces()

	for cell_variant in grid_manager.tiles.keys():
		var cell: Vector2i = cell_variant as Vector2i
		var tile: BattleTileData = grid_manager.get_tile(cell)

		if tile == null:
			continue

		var instance := tile_surface_scene.instantiate()

		if instance == null:
			push_error("SurfaceManager: impossible d'instancier TileSurface.")
			continue

		if not instance is TileSurface:
			push_error(
				"SurfaceManager: la scène assignée n'est pas une TileSurface. Type actuel: "
				+ str(instance.get_class())
			)
			instance.queue_free()
			continue

		var surface := instance as TileSurface
		surfaces_root.add_child(surface)

		var polygon := get_polygon_for_surface_type(tile.surface_type)
		var z := grid_manager.get_render_z_index(cell, tile.height, 20)

		surface.global_position = grid_manager.get_world_position_from_cell(cell)
		print("Surface créée cell=", cell, " pos=", surface.global_position)
		surface.collision_layer = surface_collision_layer
		surface.collision_mask = 0
		surface.setup(tile, polygon, z)

		tile.surface = surface
		surfaces[cell] = surface

	print("SurfaceManager: surfaces générées = ", surfaces.size())

func clear_surfaces() -> void:
	for child: Node in surfaces_root.get_children():
		child.queue_free()

	surfaces.clear()

func get_polygon_for_surface_type(surface_type: String) -> PackedVector2Array:
	match surface_type:
		"stairs_left":
			return PackedVector2Array([
				Vector2(0, -tile_half_height),
				Vector2(tile_half_width, tile_half_height*2),
				Vector2(0, tile_half_height*3),
				Vector2(-tile_half_width, 0),
			])

		"stairs_right":
			return PackedVector2Array([
				Vector2(0, -tile_half_height),
				Vector2(tile_half_width, 0),
				Vector2(0, tile_half_height * 3),
				Vector2(-tile_half_width, tile_half_height * 2),
			])

		_:
			return PackedVector2Array([
				Vector2(0, -tile_half_height),
				Vector2(tile_half_width, 0),
				Vector2(0, tile_half_height),
				Vector2(-tile_half_width, 0),
			])

func clear_highlights() -> void:
	for node: Polygon2D in highlight_nodes:
		if is_instance_valid(node):
			node.queue_free()

	highlight_nodes.clear()

func show_move_cells(cells: Array[Vector2i]) -> void:
	clear_highlights()

	print("SurfaceManager: show_move_cells count=", cells.size())

	for cell: Vector2i in cells:
		var surface := get_surface_at_cell(cell)

		if surface == null:
			print("Surface manquante pour cell=", cell)
			continue

		var polygon := Polygon2D.new()
		surfaces_root.add_child(polygon)

		polygon.polygon = surface.surface_polygon
		polygon.color = Color(0.2, 0.6, 1.0, 0.45)

		polygon.global_position = surface.global_position
		polygon.z_as_relative = false
		polygon.z_index = 4095

		highlight_nodes.append(polygon)

		print("Highlight créé cell=", cell, " pos=", polygon.global_position)

func get_unit_world_position(cell: Vector2i) -> Vector2:
	var tile := grid_manager.get_tile(cell)

	if tile == null:
		return grid_manager.get_world_position_from_cell(cell)

	var base_pos := grid_manager.get_world_position_from_cell(cell)
	var anchor_offset := get_unit_anchor_offset_for_surface_type(tile.surface_type)

	return base_pos + anchor_offset
	
func get_unit_anchor_offset_for_surface_type(surface_type: String) -> Vector2:
	match surface_type:
		"stairs_left":
			return Vector2(0, tile_half_height * 1.0)

		"stairs_right":
			return Vector2(0, tile_half_height * 1.0)

		_:
			return Vector2.ZERO
			
func get_surface_at_cell(cell: Vector2i) -> TileSurface:
	return surfaces.get(cell, null)

func get_surface_under_global_position(global_pos: Vector2) -> TileSurface:
	var best_surface: TileSurface = null
	var best_z: int = -999999999

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
		print("Surface trouvée : ", best_surface.grid_position)
	else:
		print("Aucune surface pour global_pos=", global_pos)

	return best_surface
