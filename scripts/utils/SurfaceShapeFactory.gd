class_name SurfaceShapeFactory
extends RefCounted

const FLAT := "flat"
const STAIRS_LEFT := "stairs_left"
const STAIRS_RIGHT := "stairs_right"

static func get_polygon(
	surface_type: String,
	tile_half_width: float,
	tile_half_height: float
) -> PackedVector2Array:
	match surface_type:
		STAIRS_LEFT:
			return PackedVector2Array([
				Vector2(0, -tile_half_height),
				Vector2(tile_half_width, tile_half_height * 2.0),
				Vector2(0, tile_half_height * 3.0),
				Vector2(-tile_half_width, 0),
			])

		STAIRS_RIGHT:
			return PackedVector2Array([
				Vector2(0, -tile_half_height),
				Vector2(tile_half_width, 0),
				Vector2(0, tile_half_height * 3.0),
				Vector2(-tile_half_width, tile_half_height * 2.0),
			])

		_:
			return PackedVector2Array([
				Vector2(0, -tile_half_height),
				Vector2(tile_half_width, 0),
				Vector2(0, tile_half_height),
				Vector2(-tile_half_width, 0),
			])
