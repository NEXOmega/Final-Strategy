class_name SurfaceAnchorFactory
extends RefCounted

static func get_unit_anchor_offset(
	surface_type: String,
	tile_half_height: float
) -> Vector2:
	match surface_type:
		"stairs_left", "stairs_right":
			return Vector2(0, tile_half_height)

		_:
			return Vector2.ZERO
