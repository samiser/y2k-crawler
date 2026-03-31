extends Node3D
class_name Player

signal moved(new_grid_pos: Vector2i)

@export var grid_path: NodePath
@export var move_duration := 0.25
@export var turn_duration := 0.25

enum Facing { NORTH, EAST, SOUTH, WEST }

var grid: Grid
var grid_pos := Vector2i.ZERO
@export var facing := Facing.NORTH
var _is_busy := false
var _teleporting := false
var _current_tween: Tween
var coins := 0
var unlocked_items: Array = []
var selected_item: int = -1

@onready var player_sfx_stream: AudioStreamPlayer2D = $PlayerSfxStream

@onready var coin_label: Label = %CoinLabel
@onready var terminal_ui: Window = $TerminalUI
@onready var fp_sprite: Sprite2D = %FpSprite
@onready var hotbar: Control = %Hotbar
@onready var fade_rect: ColorRect = %FadeRect
@onready var camera_3d: Camera3D = $Camera3D
@onready var radar: Panel = %Radar
@onready var radar_camera: Camera3D = %RadarCamera
@onready var log_v_container: VBoxContainer = %LogVContainer
@onready var log_text: Label = %LogText

@onready var player_sprite: Sprite2D = %PlayerSprite
var face_frame : int = 0
var face_reversing : bool = false
var override_face : bool = false

const FACING_TO_DIRECTION := {
	Facing.NORTH: Vector2i(0, 1),
	Facing.EAST: Vector2i(-1, 0),
	Facing.SOUTH: Vector2i(0, -1),
	Facing.WEST: Vector2i(1, 0),
}

const FACING_TO_ANGLE := {
	Facing.NORTH: PI,
	Facing.EAST: PI / 2,
	Facing.SOUTH: 0.0,
	Facing.WEST: -PI / 2,
}

func _ready() -> void:
	fp_sprite.visible = false
	fp_sprite.position.y = 128.0
	
	log_text.visible = false
	
	if grid_path:
		grid = get_node(grid_path) as Grid
	if grid:
		grid_pos = grid.world_to_grid(position)
		position = grid.grid_to_world(grid_pos)
	rotation.y = FACING_TO_ANGLE[facing]
	if terminal_ui:
		terminal_ui.closed.connect(_on_terminal_closed)
	if hotbar:
		hotbar.item_selected.connect(_on_item_selected)
	
	teleport_to(grid_pos, facing, true)

func _process(_delta: float) -> void:
	fp_sprite.position.y += sin(Time.get_ticks_msec() * 0.1 * _delta) * 0.2 # weapon bob

	_face_animation()
	_sync_radar_camera()

	if not _is_busy and not _teleporting:
		handle_input()

func _sync_radar_camera() -> void:
	if radar_camera:
		radar_camera.global_position.x = global_position.x
		radar_camera.global_position.z = global_position.z
		radar_camera.rotation.y = rotation.y

func _face_animation() -> void:
	if override_face:
		return
	
	if(Engine.get_frames_drawn() % 18 == 0):
		if face_frame == 0:
				face_reversing = false
		elif face_frame >= 2:
			face_reversing = true
		
		var dir := 1
		if face_reversing:
			dir = -1
		face_frame += dir
		
		if randi_range(0, 10) == 1: # look left/right
			face_frame = randi_range(3, 4)
	
	player_sprite.frame = face_frame

func _unhandled_input(event: InputEvent) -> void:
	if _is_busy:
		return
	if event.is_action_pressed("use"):
		try_use()

func handle_input() -> void:
	if Input.is_action_pressed("forward"):
		try_move(FACING_TO_DIRECTION[facing])
	elif Input.is_action_pressed("back"):
		try_move(-FACING_TO_DIRECTION[facing])
	elif Input.is_action_pressed("left"):
		try_move(FACING_TO_DIRECTION[wrapi(facing - 1, 0, 4)])
	elif Input.is_action_pressed("right"):
		try_move(FACING_TO_DIRECTION[wrapi(facing + 1, 0, 4)])
	elif Input.is_action_pressed("turn_left"):
		turn(-1)
	elif Input.is_action_pressed("turn_right"):
		turn(1)

func try_move(direction: Vector2i) -> void:
	if not grid:
		return
	
	var new_grid_pos := grid_pos + direction

	if not grid.has_tile_at(new_grid_pos):
		return

	if is_blocked(new_grid_pos):
		return

	grid_pos = new_grid_pos
	var target_position := grid.grid_to_world(grid_pos)
	target_position.y = position.y

	_is_busy = true
	_current_tween = create_tween()
	_current_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_current_tween.tween_property(self, "position", target_position, move_duration)
	_current_tween.finished.connect(func(): _is_busy = false)

	moved.emit(grid_pos)
	_check_for_coins()

func _check_for_coins() -> void:
	if not grid:
		return
	for item in grid.get_items_at(grid_pos):
		if item is Coin:
			item.queue_free()
			coins += 1
			player_sfx_stream.stream = load("res://Audio/coin.mp3")
			player_sfx_stream.play()
			_update_coin_label()

func _update_coin_label() -> void:
	if coin_label:
		coin_label.text = "Coins: %d" % coins

func is_blocked(check_pos: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group("firewall_enemies"):
		if node.is_at(check_pos):
			return true
	for node in get_tree().get_nodes_in_group("barriers"):
		if node.is_at(check_pos):
			return true
	return false

func turn(direction: int) -> void:
	facing = wrapi(facing + direction, 0, 4) as Facing
	var target_angle: float = FACING_TO_ANGLE[facing]

	_is_busy = true
	_current_tween = create_tween()
	_current_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_current_tween.tween_method(_set_rotation_y, rotation.y, _shortest_angle(rotation.y, target_angle), turn_duration)
	_current_tween.finished.connect(func(): _is_busy = false)

func teleport_to(new_grid_pos: Vector2i, direction: Facing, skip_intro: bool) -> void:
	player_sfx_stream.stream = load("res://Audio/teleport.mp3")
	player_sfx_stream.play()
	
	_is_busy = true
	_teleporting = true
	
	if not skip_intro:
		override_face = true
		player_sprite.frame = 5
		
		var tween := get_tree().create_tween()
		tween.tween_property(fade_rect, "modulate", Color.WHITE, 1.0)
		tween.parallel().tween_property(camera_3d, "fov", 10, 1.0)
		await tween.finished
	else:
		camera_3d.fov = 10
		fade_rect.modulate = Color.WHITE
	
	if _current_tween and _current_tween.is_running():
		_current_tween.kill()
	
	rotation.y = FACING_TO_ANGLE[direction]
	facing = direction
	grid_pos = new_grid_pos
	position = grid.grid_to_world(grid_pos)
	position.y = 0
	
	var timer := get_tree().create_timer(1.0)
	await timer.timeout
	
	var tween := get_tree().create_tween() # fade out
	tween.tween_property(fade_rect, "modulate", Color.TRANSPARENT, 1.0)
	tween.parallel().tween_property(camera_3d, "fov", 60, 1.0)
	await tween.finished
	
	if not skip_intro:
		add_log("You've been teleported!")
	
	player_sprite.frame = 0
	
	_is_busy = false
	_teleporting = false
	override_face = false

func _set_rotation_y(value: float) -> void:
	rotation.y = value

func _shortest_angle(from: float, to: float) -> float:
	var diff := wrapf(to - from, -PI, PI)
	return from + diff

func open_terminal_ui() -> void:
	if terminal_ui:
		_is_busy = true
		terminal_ui.show()

func _on_terminal_closed() -> void:
	_is_busy = false

func _on_item_selected(item: int, force: bool) -> void:
	if not force and (selected_item == item or _is_busy): # already held or busy
		return
	
	selected_item = item
		
	if fp_sprite:
		if fp_sprite.visible == true: # lower weapon sprite
			if not force:
				_is_busy = true
			var tween := get_tree().create_tween()
			tween.tween_property(fp_sprite, "position:y", 128.0, 0.4)
			await tween.finished

		fp_sprite.visible = true
		fp_sprite.frame = (item + 1) * 2 - 2
		
		var tween := get_tree().create_tween() # raise weapon sprite
		tween.tween_property(fp_sprite, "position:y", -120.0, 0.4)
		await tween.finished
		
		if not force:
			_is_busy = false

func unlock_item(item: int) -> void:
	if item not in unlocked_items:
		unlocked_items.append(item)
		if hotbar:
			hotbar.set_unlocked(unlocked_items)
		
		if selected_item == -1:
			_on_item_selected(item, true)
		
		add_log("You unlocked a new item!")
		override_face = true
		player_sprite.frame = 6
		var timer := get_tree().create_timer(4.0)
		await timer.timeout
		player_sprite.frame = 0
		override_face = false
		

func try_use() -> void:
	if _try_interact_terminal():
		return
	if _try_interact_msn():
		return
	if selected_item < 0:
		return
	_play_use_animation()

	if selected_item == 0:
		_use_water_gun()

func _try_interact_terminal() -> bool:
	for terminal in get_tree().get_nodes_in_group("terminals"):
		if terminal.is_at(grid_pos):
			open_terminal_ui()
			return true
	return false

func _try_interact_msn() -> bool:
	var facing_pos: Vector2i = grid_pos + FACING_TO_DIRECTION[facing]
	for msn in get_tree().get_nodes_in_group("msn"):
		if msn.is_at(facing_pos):
			msn.interact()
			return true
	return false

func _play_use_animation() -> void:
	if not fp_sprite:
		return
	var base_frame: int = (selected_item + 1) * 2 - 2
	fp_sprite.frame = base_frame + 1
	get_tree().create_timer(0.15).timeout.connect(func(): fp_sprite.frame = base_frame)

func _use_water_gun() -> void:
	player_sfx_stream.stream = load("res://Audio/Tools/water_spray.mp3")
	player_sfx_stream.play()
	
	var target_pos: Vector2i = grid_pos + FACING_TO_DIRECTION[facing]
	for enemy in get_tree().get_nodes_in_group("firewall_enemies"):
		if enemy.is_at(target_pos):
			enemy.stun(4)
			add_log("You stunned Firewall for 4 turns!")
			return

func add_log(message: String) -> void:
	if message.length() == 0:
		return
	
	if log_v_container.get_child_count() > 6:
		log_v_container.get_child(log_v_container.get_child_count() - 1).queue_free()
	
	var new_log : Label = log_text.duplicate()
	new_log.text = "[" + Time.get_time_string_from_system() + "] " + message
	new_log.visible = true
	log_v_container.add_child(new_log)
	
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func(): if new_log: new_log.queue_free())
