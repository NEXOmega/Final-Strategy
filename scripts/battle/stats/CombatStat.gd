class_name CombatStats
extends Resource

@export var values: Array[CombatStatValue] = []


func to_dictionary() -> Dictionary:
	var result: Dictionary = {}

	for entry: CombatStatValue in values:
		if entry == null:
			continue

		result[entry.stat_type] = int(result.get(entry.stat_type, 0)) + entry.value

	return result


func get_stat(stat_type: BattleStats.StatType) -> int:
	var dictionary: Dictionary = to_dictionary()
	return int(dictionary.get(stat_type, 0))


func has_stat(stat_type: BattleStats.StatType) -> bool:
	for entry: CombatStatValue in values:
		if entry == null:
			continue

		if entry.stat_type == stat_type:
			return true

	return false
