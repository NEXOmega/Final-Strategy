class_name BattleStatModifier
extends Resource

var add_values: Dictionary = {}
var multiply_values: Dictionary = {}

@export var priority: int = 0
@export var remove_on_condition_fail: bool = true

func add(stat_type: BattleStats.StatType, value: float) -> void:
	add_values[stat_type] = get_add(stat_type) + value

func multiply(stat_type: BattleStats.StatType, value: float) -> void:
	multiply_values[stat_type] = get_multiply(stat_type) * value

func get_add(stat_type: BattleStats.StatType) -> float:
	return float(add_values.get(stat_type, 0.0))

func get_multiply(stat_type: BattleStats.StatType) -> float:
	return float(multiply_values.get(stat_type, 1.0))
