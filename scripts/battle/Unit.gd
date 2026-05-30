class_name Unit
extends Node2D

var unit_name: String = "Unit"
var team_id: int = 0
var grid_position: Vector2i = Vector2i.ZERO

var max_hp: int = 100
var hp: int = 100

var max_mp: int = 4
var current_mp: int = 4

var jump: int = 1
var max_fall: int = 2

var has_ended_turn: bool = false
var has_moved_this_turn: bool = false

func setup(
	p_unit_name: String,
	p_team_id: int,
	p_grid_position: Vector2i
) -> void:
	unit_name = p_unit_name
	team_id = p_team_id
	grid_position = p_grid_position

func start_turn() -> void:
	has_ended_turn = false
	has_moved_this_turn = false
	current_mp = max_mp

	print(unit_name, " commence son tour. PM=", current_mp, "/", max_mp)

func end_turn() -> void:
	has_ended_turn = true
	print(unit_name, " termine son tour.")

func mark_moved() -> void:
	has_moved_this_turn = true

func reset_movement_points() -> void:
	current_mp = max_mp
