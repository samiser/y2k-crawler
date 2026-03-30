@tool
extends HBoxContainer

@onready var sprite: Sprite2D = $Sprite/Control/Sprite2D
@onready var title_label: RichTextLabel = $VBoxContainer/Title
@onready var description_label: RichTextLabel = $VBoxContainer/Description
@onready var purchase_button: Button = $Button

@export var frame: int = 0:
	set(value):
		frame = value
		if Engine.is_editor_hint():
			sprite.frame = value

@export var title: String = "Gun":
	set(value):
		title = value
		if Engine.is_editor_hint():
			title_label.text = value

@export var description: String = "Item description":
	set(value):
		description = value
		if Engine.is_editor_hint():
			description_label.text = value

@export var cost: int = 5:
	set(value):
		cost = value
		if Engine.is_editor_hint():
			purchase_button.text = "%d Coins" % cost 

func _ready() -> void:
	sprite.frame = frame
	title_label.text = title
	description_label.text = description
	purchase_button.text = "%d Coins" % cost 
