class_name BattleActionMenu
extends Control

signal move_requested
signal abilities_requested
signal wait_requested

@onready var move_button: Button = $PanelContainer/VBoxContainer/MoveButton
@onready var abilities_button: Button = $PanelContainer/VBoxContainer/AbilitiesButton
@onready var wait_button: Button = $PanelContainer/VBoxContainer/WaitButton

func _ready() -> void:
	position = Vector2(20, 20)
	custom_minimum_size = Vector2(220, 140)
	size = Vector2(220, 140)

	hide()

	move_button.pressed.connect(_on_move_pressed)
	abilities_button.pressed.connect(_on_abilities_pressed)
	wait_button.pressed.connect(_on_wait_pressed)

func open_for_unit(unit: Unit) -> void:
	print("DEBUG BattleActionMenu.open_for_unit appelé")

	if unit == null:
		hide()
		return

	move_button.disabled = (
		unit.get_stat(BattleStats.StatType.MOVE_POINTS_NOW) <= 0
		or unit.has_moved_this_turn
	)
	abilities_button.disabled = unit.abilities.is_empty() or not unit.can_act()
	wait_button.disabled = false

	position = Vector2(20, 20)
	custom_minimum_size = Vector2(220, 140)
	size = Vector2(220, 140)

	show()

	print(
		"DEBUG BattleActionMenu visible=",
		visible,
		" position=",
		position,
		" size=",
		size,
		" parent=",
		get_parent().name if get_parent() != null else "NO_PARENT"
	)

func close() -> void:
	hide()

func _on_move_pressed() -> void:
	move_requested.emit()

func _on_abilities_pressed() -> void:
	abilities_requested.emit()

func _on_wait_pressed() -> void:
	wait_requested.emit()
