class_name AbilityMenu
extends Control

signal ability_selected(ability: AbilityDefinition)
signal cancelled

@onready var ability_list: VBoxContainer = %AbilityList

func _ready() -> void:
	hide()

func open_for_unit(unit: Unit) -> void:
	clear_buttons()

	if unit == null:
		hide()
		return

	for ability: AbilityDefinition in unit.abilities:
		if ability == null:
			continue

		var button := Button.new()
		button.text = build_ability_label(ability, unit)
		button.disabled = not ability.can_pay_cost(unit)

		button.pressed.connect(func() -> void:
			ability_selected.emit(ability)
		)

		ability_list.add_child(button)

	show()

func close() -> void:
	hide()
	clear_buttons()

func clear_buttons() -> void:
	for child: Node in ability_list.get_children():
		child.queue_free()

func build_ability_label(ability: AbilityDefinition, unit: Unit) -> String:
	var label := ability.display_name

	label += " | Pow " + str(ability.power)
	label += " | Range " + str(ability.min_range) + "-" + str(ability.max_range)

	if ability.action_cost > 0:
		label += " | Act " + str(ability.action_cost)

	return label
