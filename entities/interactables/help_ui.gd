extends Window

var player: Player
var init_pos : Vector2i
var init_size : Vector2i

func _ready() -> void:
	add_to_group("ui_window")
	init_pos = position
	init_size = size
	close_requested.connect(_on_close)
	hide()

func _display() -> void:
	position = init_pos
	size = init_size
	show()

func _on_close() -> void:
	hide()
