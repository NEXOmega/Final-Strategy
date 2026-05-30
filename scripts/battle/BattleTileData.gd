class_name BattleTileData
extends RefCounted

var grid_position: Vector2i
var height: int = 0
var surface_type: String = "flat"
var movement_cost: int = 1

var walkable: bool = true
var occupied_by: Node = null

var surface: TileSurface = null

func _init(
	p_grid_position: Vector2i,
	p_height: int = 0,
	p_surface_type: String = "flat",
	p_movement_cost: int = 1,
	p_walkable: bool = true
) -> void:
	grid_position = p_grid_position
	height = p_height
	surface_type = p_surface_type
	movement_cost = max(1, p_movement_cost)
	walkable = p_walkable
