class_name Unit
extends Node2D

var unit_name: String = "Unit"
var team_id: int = 0
var grid_position: Vector2i = Vector2i.ZERO

var max_hp: int = 100
var hp: int = 100

var max_mp: int = 4
var current_mp: int = 4

var max_actions: int = 1
var current_actions: int = 1

var jump: int = 1
var max_fall: int = 2

var initiative: int = 10

@export var unit_definition: UnitDefinition

var stats: CombatStats
var abilities: Array[AbilityDefinition] = []

var has_moved_this_turn: bool = false
var has_acted_this_turn: bool = false
var has_ended_turn: bool = false

func setup(
	p_unit_name: String,
	p_team_id: int,
	p_grid_position: Vector2i
) -> void:
	unit_name = p_unit_name
	team_id = p_team_id
	grid_position = p_grid_position

func start_turn() -> void:
	has_moved_this_turn = false
	has_acted_this_turn = false
	has_ended_turn = false

	current_mp = max_mp
	current_actions = max_actions

	print(unit_name, " commence son tour. PM=", current_mp, "/", max_mp, " Actions=", current_actions, "/", max_actions)

func end_turn() -> void:
	has_ended_turn = true
	current_mp = 0
	current_actions = 0

	print(unit_name, " termine son tour.")

func mark_moved() -> void:
	has_moved_this_turn = true

func can_act() -> bool:
	return current_actions > 0 and not has_acted_this_turn

func consume_action() -> void:
	if current_actions <= 0:
		return

	current_actions -= 1
	has_acted_this_turn = true

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	print(unit_name, " subit ", amount, " dégâts. HP=", hp, "/", max_hp)

func is_dead() -> bool:
	return hp <= 0

func is_enemy_of(other_unit: Unit) -> bool:
	if other_unit == null:
		return false

	return team_id != other_unit.team_id

func apply_definition(definition: UnitDefinition) -> void:
	unit_definition = definition

	if definition == null:
		return

	unit_name = definition.display_name

	stats = build_runtime_stats(definition)

	max_hp = stats.max_hp
	hp = max_hp

	max_mp = stats.max_move_points
	current_mp = max_mp

	max_actions = stats.max_actions
	current_actions = max_actions

	jump = stats.jump
	max_fall = stats.max_fall
	initiative = stats.speed

	abilities = definition.get_all_abilities()

func build_runtime_stats(definition: UnitDefinition) -> CombatStats:
	var result := CombatStats.new()

	if definition.race != null and definition.race.base_stats != null:
		_add_stats(result, definition.race.base_stats)

	if definition.main_job != null and definition.main_job.stat_bonus != null:
		_add_stats(result, definition.main_job.stat_bonus)

	if definition.sub_job != null and definition.sub_job.stat_bonus != null:
		_add_stats(result, definition.sub_job.stat_bonus)

	if definition.base_stats_override != null:
		_add_stats(result, definition.base_stats_override)

	return result

func _add_stats(target: CombatStats, source: CombatStats) -> void:
	target.max_hp += source.max_hp
	target.max_move_points += source.max_move_points
	target.max_actions += source.max_actions

	target.attack += source.attack
	target.defense += source.defense
	target.magic_attack += source.magic_attack
	target.magic_defense += source.magic_defense

	target.speed += source.speed
	target.jump += source.jump
	target.max_fall += source.max_fall
