class_name UnitDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = "Unit"

@export var race: RaceDefinition
@export var main_job: JobDefinition
@export var sub_job: JobDefinition

@export var base_stats_override: CombatStats
@export var innate_abilities: Array[AbilityDefinition] = []

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
