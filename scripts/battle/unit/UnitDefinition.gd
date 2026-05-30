class_name UnitDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = "Unit"

@export var race: RaceDefinition
@export var main_job: JobDefinition
@export var sub_job: JobDefinition

@export var base_stats_override: CombatStats
@export var innate_abilities: Array[AbilityDefinition] = []

func build_starting_stats() -> BattleStats:
	var values: Dictionary = {}

	_add_combat_stats_to_dictionary(values, race.base_stats if race != null else null)
	_add_combat_stats_to_dictionary(values, main_job.stat_bonus if main_job != null else null)
	_add_combat_stats_to_dictionary(values, sub_job.stat_bonus if sub_job != null else null)
	_add_combat_stats_to_dictionary(values, base_stats_override)

	var stats := BattleStats.new()
	stats.setup_from_dictionary(values)

	stats.restore_to_max(BattleStats.StatType.HP_NOW, BattleStats.StatType.HP_MAX)
	stats.restore_to_max(BattleStats.StatType.MOVE_POINTS_NOW, BattleStats.StatType.MOVE_POINTS_MAX)
	stats.restore_to_max(BattleStats.StatType.ACTIONS_NOW, BattleStats.StatType.ACTIONS_MAX)

	return stats

func _add_combat_stats_to_dictionary(values: Dictionary, combat_stats: CombatStats) -> void:
	if combat_stats == null:
		return

	var source: Dictionary = combat_stats.to_dictionary()

	for key in source.keys():
		var stat_type: BattleStats.StatType = key as BattleStats.StatType
		var amount: int = int(source[key])

		if amount == 0:
			continue

		values[stat_type] = int(values.get(stat_type, 0)) + amount
		
func get_all_abilities() -> Array[AbilityDefinition]:
	var result: Array[AbilityDefinition] = []

	for ability: AbilityDefinition in innate_abilities:
		if ability != null and not result.has(ability):
			result.append(ability)

	if main_job != null:
		for ability: AbilityDefinition in main_job.get_available_abilities():
			if ability != null and not result.has(ability):
				result.append(ability)

	if sub_job != null:
		for ability: AbilityDefinition in sub_job.get_available_abilities():
			if ability != null and not result.has(ability):
				result.append(ability)

	return result
