class_name TileCustomDataReader
extends RefCounted

static func get_int(tile_data: TileData, key: String, default_value: int = 0) -> int:
	if tile_data == null:
		return default_value

	var value = tile_data.get_custom_data(key)

	if value == null:
		return default_value

	return int(value)

static func get_float(tile_data: TileData, key: String, default_value: float = 0.0) -> float:
	if tile_data == null:
		return default_value

	var value = tile_data.get_custom_data(key)

	if value == null:
		return default_value

	return float(value)

static func get_string(tile_data: TileData, key: String, default_value: String = "") -> String:
	if tile_data == null:
		return default_value

	var value = tile_data.get_custom_data(key)

	if value == null:
		return default_value

	return str(value)

static func get_bool(tile_data: TileData, key: String, default_value: bool = false) -> bool:
	if tile_data == null:
		return default_value

	var value = tile_data.get_custom_data(key)

	if value == null:
		return default_value

	return bool(value)
