class_name TileSurface
extends Area2D

@onready var collision_polygon: CollisionPolygon2D = get_node("CollisionPolygon2D") as CollisionPolygon2D

var grid_position: Vector2i
var tile_data: BattleTileData
var surface_polygon: PackedVector2Array = PackedVector2Array()

func setup(
	p_tile_data: BattleTileData,
	p_polygon: PackedVector2Array,
	p_z_index: int
) -> void:
	tile_data = p_tile_data
	grid_position = p_tile_data.grid_position
	surface_polygon = p_polygon

	if collision_polygon != null:
		collision_polygon.polygon = surface_polygon

	z_as_relative = false
	z_index = p_z_index

func contains_global_point(global_pos: Vector2) -> bool:
	var local_pos := to_local(global_pos)
	return Geometry2D.is_point_in_polygon(local_pos, surface_polygon)
