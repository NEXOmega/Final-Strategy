class_name BattleStats
extends Resource

var base_stats: Dictionary = {}
var modifiers: Dictionary = {}


enum StatType {
	HP_NOW,
	HP_MAX,

	MOVE_POINTS_NOW,
	MOVE_POINTS_MAX,

	ACTIONS_NOW,
	ACTIONS_MAX,

	ATTACK,
	DEFENSE,

	MAGIC_ATTACK,
	MAGIC_DEFENSE,

	SPEED,

	JUMP,
	MAX_FALL,

	CRITICAL_CHANCE,
	CRITICAL_DAMAGE,

	FIRE_RESISTANCE,
	ICE_RESISTANCE,
	LIGHTNING_RESISTANCE,
	WATER_RESISTANCE,
	EARTH_RESISTANCE,
	WIND_RESISTANCE,
	HOLY_RESISTANCE,
	DARK_RESISTANCE,
}

func get_base(stat_type: StatType) -> int:
	return int(base_stats.get(stat_type, 0))

func set_base(stat_type: StatType, value: int) -> void:
	base_stats[stat_type] = value

func add_base(stat_type: StatType, amount: int) -> void:
	set_base(stat_type, get_base(stat_type) + amount)

func get_stat(stat_type: StatType) -> int:
	var value: float = float(get_base(stat_type))

	var sorted_modifiers: Array[BattleStatModifier] = _get_sorted_modifiers()

	for modifier: BattleStatModifier in sorted_modifiers:
		value += modifier.get_add(stat_type)
		value *= modifier.get_multiply(stat_type)

	return int(round(value))

func add_modifier(id: String, modifier: BattleStatModifier) -> void:
	if id.is_empty():
		push_error("BattleStats: modifier id vide.")
		return

	if modifier == null:
		return

	modifiers[id] = modifier

func remove_modifier(id: String) -> void:
	modifiers.erase(id)

func has_modifier(id: String) -> bool:
	return modifiers.has(id)

func clear_modifiers() -> void:
	modifiers.clear()

func restore_to_max(current_stat: StatType, max_stat: StatType) -> void:
	set_base(current_stat, get_stat(max_stat))

func clamp_current_to_max(current_stat: StatType, max_stat: StatType) -> void:
	var current_value: int = get_base(current_stat)
	var max_value: int = get_stat(max_stat)

	set_base(current_stat, clamp(current_value, 0, max_value))

func setup_from_dictionary(values: Dictionary) -> void:
	base_stats.clear()
	modifiers.clear()

	for key in values.keys():
		var stat_type: StatType = int(key) as StatType
		base_stats[stat_type] = int(values[key])

func duplicate_stats() -> BattleStats:
	var copy := BattleStats.new()

	copy.base_stats = base_stats.duplicate(true)
	copy.modifiers = modifiers.duplicate(true)

	return copy

func _get_sorted_modifiers() -> Array[BattleStatModifier]:
	var result: Array[BattleStatModifier] = []

	for modifier_variant in modifiers.values():
		var modifier := modifier_variant as BattleStatModifier

		if modifier == null:
			continue

		result.append(modifier)

	result.sort_custom(func(a: BattleStatModifier, b: BattleStatModifier) -> bool:
		return a.priority < b.priority
	)

	return result
