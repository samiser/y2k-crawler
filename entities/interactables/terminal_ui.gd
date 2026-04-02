extends Window

signal closed

var player: Player
var items: Array = []
var init_pos : Vector2i
var init_size : Vector2i

func _ready() -> void:
	add_to_group("ui_window")
	init_pos = position
	init_size = size
	hide()
	close_requested.connect(_on_close)
	visibility_changed.connect(_on_visibility_changed)
	player = get_parent() as Player

	for item in get_tree().get_nodes_in_group("terminal_items"):
		items.append(item)
		item.purchase_requested.connect(_on_purchase_requested.bind(item))

func _on_visibility_changed() -> void:
	if visible and player:
		position = init_pos
		size = init_size
		for item in items:
			if item.frame in player.unlocked_items:
				item.set_purchased()
		_focus_first_button()

func _focus_first_button() -> void:
	for item in items:
		if not item.purchase_button.disabled:
			item.purchase_button.grab_focus()
			return

func _on_close() -> void:
	hide()
	closed.emit()

func _on_purchase_requested(item_type: int, cost: int, item_node: Node) -> void:
	if not player:
		return
	if player.coins >= cost:
		player.coins -= cost
		player._update_coin_label()
		player.unlock_item(item_type)
		item_node.set_purchased()
