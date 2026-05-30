class_name RaceDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = "Race"

@export var base_stats: CombatStats
@export var allowed_jobs: Array[JobDefinition] = []
