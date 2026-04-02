extends Control

signal item_selected(item: int)

enum Item { WATER_GUN, METAL_DETECTOR, MAGNET }

@onready var slots: Dictionary = {
	Item.WATER_GUN: $HBoxContainer/WaterGun,
	Item.METAL_DETECTOR: $HBoxContainer/MetalDetector,
	Item.MAGNET: $HBoxContainer/Magnet,
}

const PRESSED = preload("uid://cibnnyejeymbj")

var default_style: StyleBox
var selected_slot: Control = null

func _ready() -> void:
	for item in slots:
		var slot: Control = slots[item]
		if not default_style:
			default_style = slot.get_theme_stylebox("panel").duplicate()
		slot.gui_input.connect(_on_slot_input.bind(item))
		slot.hide()

func _on_slot_input(event: InputEvent, item: Item) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		item_selected.emit(item, false)
		get_viewport().set_input_as_handled()

func set_unlocked(unlocked: Array) -> void:
	for item in slots:
		if item in unlocked:
			slots[item].show()
		else:
			slots[item].hide()

func set_selected(item: int) -> void:
	if selected_slot:
		selected_slot.add_theme_stylebox_override("panel", default_style)

	if item in slots:
		selected_slot = slots[item]
		selected_slot.add_theme_stylebox_override("panel", PRESSED)
