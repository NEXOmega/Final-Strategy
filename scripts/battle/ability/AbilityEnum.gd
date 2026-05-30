class_name AbilityEnums
extends RefCounted

enum AbilityTargetType {
	ENEMY,
	ALLY,
	SELF,
	EMPTY_CELL,
	ANY_UNIT,
	ANY_CELL
}

enum AbilityShape {
	SINGLE,
	CROSS,
	DIAMOND,
	LINE
}

enum DamageType {
	PHYSICAL,
	MAGICAL,
	HEAL,
	TRUE_DAMAGE
}

enum Element {
	NONE,
	FIRE,
	ICE,
	LIGHTNING,
	WATER,
	EARTH,
	WIND,
	HOLY,
	DARK
}
