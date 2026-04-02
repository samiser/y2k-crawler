extends Window

var player: Player
var init_pos : Vector2i
var init_size : Vector2i
@onready var scroll_container: ScrollContainer = $Control/MarginContainer/VBoxContainer/ScrollContainer

func _ready() -> void:
	add_to_group("ui_window")
	init_pos = position
	init_size = size
	close_requested.connect(_on_close)
	player = get_parent() as Player
	hide()

func _display() -> void:
	position = init_pos
	size = init_size
	show()
	if player:
		player._is_busy = true

func _on_close() -> void:
	hide()
	if player:
		player._is_busy = false

func _process(delta: float) -> void:
	if not visible:
		return

	var joy_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(joy_y) > 0.2:
		scroll_container.scroll_vertical += int(joy_y * 500 * delta)
