class_name CombatStats
extends Resource

@export var max_hp: int = 100
@export var max_move_points: int = 4
@export var max_actions: int = 1

@export var attack: int = 10
@export var defense: int = 5

@export var magic_attack: int = 10
@export var magic_defense: int = 5

@export var speed: int = 10
@export var jump: int = 1
@export var max_fall: int = 2

func duplicate_stats() -> CombatStats:
	var copy := CombatStats.new()

	copy.max_hp = max_hp
	copy.max_move_points = max_move_points
	copy.max_actions = max_actions

	copy.attack = attack
	copy.defense = defense
	copy.magic_attack = magic_attack
	copy.magic_defense = magic_defense

	copy.speed = speed
	copy.jump = jump
	copy.max_fall = max_fall

	return copy
