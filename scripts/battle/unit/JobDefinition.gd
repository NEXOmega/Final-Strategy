class_name JobDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = "Job"

@export var stat_bonus: CombatStats
@export var abilities: Array[AbilityDefinition] = []

func get_available_abilities() -> Array[AbilityDefinition]:
	return abilities
