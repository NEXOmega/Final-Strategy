class_name BattleAttack
extends RefCounted

var source_unit: Unit = null
var ability: AbilityDefinition = null

var target_cell: Vector2i = Vector2i.ZERO
var affected_cell: Vector2i = Vector2i.ZERO

var damage_type: AbilityEnums.DamageType = AbilityEnums.DamageType.PHYSICAL
var element: AbilityEnums.Element = AbilityEnums.Element.NONE
var power: int = 0

var hits_enemies: bool = true
var hits_allies: bool = false
var hits_self: bool = false
var hits_objects: bool = false


static func from_ability(
	p_source_unit: Unit,
	p_ability: AbilityDefinition,
	p_target_cell: Vector2i,
	p_affected_cell: Vector2i
) -> BattleAttack:
	var attack := BattleAttack.new()

	attack.source_unit = p_source_unit
	attack.ability = p_ability
	attack.target_cell = p_target_cell
	attack.affected_cell = p_affected_cell

	attack.damage_type = p_ability.damage_type
	attack.element = p_ability.element
	attack.power = p_ability.power

	attack.hits_enemies = p_ability.hits_enemies
	attack.hits_allies = p_ability.hits_allies
	attack.hits_self = p_ability.hits_self
	attack.hits_objects = p_ability.hits_objects

	return attack
