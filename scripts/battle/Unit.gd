class_name Unit
extends Node2D

var unit_name: String = "Unit"
var team_id: int = 0
var grid_position: Vector2i = Vector2i.ZERO

var max_hp: int = 100
var hp: int = 100

var max_mp: int = 20
var current_mp: int = 20

var jump: int = 1
var max_fall: int = 2

func setup(
	p_unit_name: String,
	p_team_id: int,
	p_grid_position: Vector2i
) -> void:
	unit_name = p_unit_name
	team_id = p_team_id
	grid_position = p_grid_position
