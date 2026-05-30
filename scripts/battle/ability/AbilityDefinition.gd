class_name AbilityDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = "Ability"
@export_multiline var description: String = ""

@export var target_type: AbilityEnums.AbilityTargetType = AbilityEnums.AbilityTargetType.ENEMY
@export var shape: AbilityEnums.AbilityShape = AbilityEnums.AbilityShape.SINGLE

@export var damage_type: AbilityEnums.DamageType = AbilityEnums.DamageType.PHYSICAL
@export var element: AbilityEnums.Element = AbilityEnums.Element.NONE

@export var power: int = 10
@export var mp_cost: int = 0
@export var action_cost: int = 1

@export var min_range: int = 1
@export var max_range: int = 1
@export var area_radius: int = 0

@export var requires_line_of_sight: bool = false
@export var ends_turn_after_use: bool = true

func can_pay_cost(user: Unit) -> bool:
	if user == null:
		return false

	if user.get_stat(BattleStats.StatType.ACTIONS_NOW) < action_cost:
		return false

	return true
