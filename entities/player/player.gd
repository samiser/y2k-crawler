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
@onready var energy_label: Label = $HUD/VBoxContainer/Control/HBoxContainer/VBoxContainer/HBoxContainer/Energy/MarginContainer/HBoxContainer/EnergyLabel
var energy_lvl : int = 1

var energy := 30:
	set(value):
		if value < 0:
			value = 0
		energy = value
		if energy_bar:
			energy_bar.value = energy
		if energy == 0:
			_on_energy_depleted()

var max_energy := 30:
	set(value):
		if value > max_energy:
			energy_lvl += 1
		max_energy = value
		if energy_bar:
			energy_bar.max_value = max_energy
		if energy_label:
			energy_label.text = "Energy LvL " + str(energy_lvl)

@onready var player_sfx_stream: AudioStreamPlayer2D = $PlayerSfxStream

@onready var coin_label: Label = %CoinLabel
@onready var terminal_ui: Window = $TerminalUI
@onready var fp_sprite: Sprite2D = %FpSprite
@onready var hotbar: Control = %Hotbar
@onready var fade_rect: ColorRect = %FadeRect
@onready var camera_3d: Camera3D = $Camera3D
@onready var radar: Panel = %Radar
@onready var radar_camera: Camera3D = %RadarCamera
@onready var radar_viewport: SubViewport = %RadarViewport
@onready var radar_image: TextureRect = %RadarImage
@onready var log_v_container: VBoxContainer = %LogVContainer
@onready var log_text: Label = %LogText
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var log_scroll_container: ScrollContainer = %LogScrollContainer
@onready var compass_dir_sprite: Sprite2D = $HUD/VBoxContainer/Control/HBoxContainer/VBoxContainer2/CompassPanel/VBoxContainer/Control/CompassDirSprite
@onready var help_ui: Window = $HelpUI

var magnet_trap_scene := preload("res://entities/interactables/magnet_trap.tscn")
var magnet_placed : bool = false

var last_terminal_pos: Vector2i
var last_terminal_facing: Facing
var has_used_terminal: bool = false

var spawn_pos: Vector2i
var spawn_facing: Facing

@onready var player_sprite: Sprite2D = %PlayerSprite
var face_frame : int = 0
var face_reversing : bool = false
var override_face : bool = false

var radar_tween: Tween

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
	
	energy_bar.value = energy
	energy_bar.max_value = max_energy
	
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

	spawn_pos = grid_pos
	spawn_facing = facing
	teleport_to(grid_pos, facing, true)

func _process(_delta: float) -> void:
	fp_sprite.position.y += sin(Time.get_ticks_msec() * 0.1 * _delta) * 0.2 # weapon bob

	_face_animation()
	
	if Input.is_action_pressed("ui_close_dialog"):
		for window in get_tree().get_nodes_in_group("ui_window"):
			window._on_close()
	elif Input.is_action_pressed("help"):
		help_ui._display()
	
	if not _is_busy and not _teleporting:
		handle_input()

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

	energy -= 1
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
	_check_for_bombs()
	_check_for_fire()
	_check_for_batteries()
	_check_for_terminals()

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

func _check_for_bombs() -> void:
	if not grid:
		return
	for item in grid.get_items_at(grid_pos):
		if item is Bomb:
			item.explode()
			screen_shake(0.5, 0.2)
			add_log("You stepped on a bomb!")
			teleport_to_checkpoint()
			return

func _check_for_fire() -> void:
	for fire in get_tree().get_nodes_in_group("fire"):
		if fire.grid_pos == grid_pos:
			player_sfx_stream.stream = load("res://Audio/Characters/player_pain.mp3")
			player_sfx_stream.play()
			energy -= 10
			screen_shake(0.15, 0.05)
			add_log("You walked through fire! -10 energy")
			return

func fireball_damage() -> void:
		player_sfx_stream.stream = load("res://Audio/Characters/player_pain.mp3")
		player_sfx_stream.play()
		energy -= 10
		screen_shake(0.15, 0.05)
		add_log("You hit a fireball! -10 energy")

func _check_for_batteries() -> void:
	if not grid:
		return
	for item in grid.get_items_at(grid_pos):
		if item is Battery:
			item.queue_free()
			max_energy += 10
			energy += 10
			add_log("Battery collected! +10 max energy")
			player_sfx_stream.stream = load("res://Audio/battery.mp3")
			player_sfx_stream.play()
			return

func _check_for_terminals() -> void:
	for terminal in get_tree().get_nodes_in_group("terminals"):
		if terminal.is_at(grid_pos):
			energy = max_energy
			last_terminal_pos = grid_pos
			add_log("Energy refilled!")
			player_sfx_stream.stream = load("res://Audio/recharge.mp3")
			player_sfx_stream.play()
			return

func screen_shake(duration: float, intensity: float) -> void:
	var original_pos := camera_3d.position
	var shake_tween := create_tween()
	var shake_count := int(duration / 0.05)
	
	override_face = true
	player_sprite.frame = 5

	for i in shake_count:
		var offset := Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			0
		)
		shake_tween.tween_property(camera_3d, "position", original_pos + offset, 0.05)

	shake_tween.tween_property(camera_3d, "position", original_pos, 0.05)
	await shake_tween.finished
	
	if not _teleporting:
		player_sprite.frame = 1
		override_face = false

func _update_coin_label() -> void:
	if coin_label:
		coin_label.text = "%d" % coins

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
	
	compass_dir_sprite.frame = facing + 1

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
	
	compass_dir_sprite.frame = facing + 1
	
	var timer := get_tree().create_timer(1.0)
	await timer.timeout
	
	var tween := get_tree().create_tween() # fade out
	tween.tween_property(fade_rect, "modulate", Color.TRANSPARENT, 1.0)
	tween.parallel().tween_property(camera_3d, "fov", 60, 1.0)
	await tween.finished
	
	if not skip_intro:
		add_log("You've been teleported!")
	
	player_sprite.frame = 0
	
	energy = max_energy
	
	_is_busy = false
	_teleporting = false
	override_face = false

func _on_energy_depleted() -> void:
	add_log("Out of energy! Returning to terminal...")
	teleport_to_checkpoint()

func teleport_to_checkpoint() -> void:
	var target_pos := last_terminal_pos if has_used_terminal else spawn_pos
	var target_facing := last_terminal_facing if has_used_terminal else spawn_facing
	teleport_to(target_pos, target_facing, false)

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
		
		if item == 2 and magnet_placed:
			fp_sprite.frame = 5
		
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
		
		player_sfx_stream.stream = load("res://Audio/Tools/tool_equip.mp3")
		player_sfx_stream.play()
		
		add_log("You unlocked a new item!")
		override_face = true
		player_sprite.frame = 6
		var timer := get_tree().create_timer(4.0)
		await timer.timeout
		player_sprite.frame = 0
		override_face = false

func remove_item(item: int) -> void:
	if item in unlocked_items:
		unlocked_items.remove_at(item)
		if hotbar:
			hotbar.set_unlocked(unlocked_items)
		
		if selected_item == item:
			fp_sprite.visible = false
			selected_item = -1

func try_use() -> void:
	if _try_interact_terminal():
		return
	if _try_interact_msn():
		return
	if selected_item < 0:
		return
	if _teleporting:
		return
	
	var valid : bool = false
	
	if selected_item == 0:
		valid = _use_water_gun()
	elif selected_item == 1:
		valid = await _use_radar()
	elif selected_item == 2:
		valid = _use_magnet()
	
	if valid:
		moved.emit(grid_pos) # skips a turn, buggy tho
		if selected_item != 1:
			energy -= 2
		_play_use_animation()

func _try_interact_terminal() -> bool:
	for terminal in get_tree().get_nodes_in_group("terminals"):
		if terminal.is_at(grid_pos):
			var terminal_facing := _angle_to_facing(terminal.rotation.y)
			if facing != terminal_facing:
				continue
			last_terminal_pos = grid_pos
			last_terminal_facing = terminal_facing
			has_used_terminal = true
			add_log("Checkpoint set!")
			open_terminal_ui()
			return true
	return false

func _angle_to_facing(angle: float) -> Facing:
	angle = wrapf(angle, -PI, PI)
	if angle > 3.0 * PI / 4.0 or angle < -3.0 * PI / 4.0:
		return Facing.NORTH
	elif angle > PI / 4.0:
		return Facing.EAST
	elif angle < -PI / 4.0:
		return Facing.WEST
	else:
		return Facing.SOUTH

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
	if selected_item != 2: # magnet
		get_tree().create_timer(0.15).timeout.connect(func(): fp_sprite.frame = base_frame)

func _use_water_gun():
	player_sfx_stream.stream = load("res://Audio/Tools/water_spray.mp3")
	player_sfx_stream.play()
	
	var target_pos: Vector2i = grid_pos + FACING_TO_DIRECTION[facing]
	for enemy in get_tree().get_nodes_in_group("firewall_enemies"):
		if enemy.is_at(target_pos):
			enemy.stun(5)
			add_log("You stunned Firewall for 5 turns!")
			return true
			
	for fire in get_tree().get_nodes_in_group("fire"):
		if fire.grid_pos == target_pos:
			fire.extinguish()
			add_log("You put out a fire!")
			return true
	
	return true

func _use_magnet():
	if magnet_placed:
		add_log("You already placed dropped your magnet!")
		return false
		
	var target_pos: Vector2i = grid_pos + FACING_TO_DIRECTION[facing]
	
	if not grid.has_tile_at(target_pos):
		add_log("You can't place a magnet there!")
		return false
	
	for barrier in get_tree().get_nodes_in_group("barriers"):
		if barrier.is_at(target_pos):
			add_log("You can't place a magnet there!")
			return false
	
	player_sfx_stream.stream = load("res://Audio/Tools/magnet_zap.mp3")
	player_sfx_stream.play()
	
	for magnet in get_tree().get_nodes_in_group("magnets"):
		if magnet.is_at(target_pos):
			add_log("You already placed a magnet there!")
			return false
	
	add_log("You placed a magnet down!")
	
	var magnet : MagnetTrap = magnet_trap_scene.instantiate()
	magnet.player = self
	magnet.grid_path = grid.get_path()
	magnet.position = grid.grid_to_world(target_pos)
	get_tree().root.add_child(magnet)
	magnet_placed = true
	
	return true

func recover_magnet() -> void:
	magnet_placed = false
	if selected_item == 2:
		fp_sprite.frame = 4
	
	player_sfx_stream.stream = load("res://Audio/Tools/magnet_recover.mp3")
	player_sfx_stream.play()
	
	add_log("Magnet returned!")

func _use_radar():
	if radar_tween and radar_tween.is_running():
		radar_tween.kill()

	_sync_radar_camera()

	# Force viewport to render and capture the image
	radar_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	var image := radar_viewport.get_texture().get_image()
	var texture := ImageTexture.create_from_image(image)
	radar_image.texture = texture

	# Show and fade out the radar
	radar.modulate.a = 1
	radar_tween = create_tween()
	radar_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	radar_tween.tween_property(radar, "modulate:a", 0, 2)
	add_log("Used radar!")
	
	return true

func _sync_radar_camera() -> void:
	if radar_camera:
		radar_camera.global_position.x = global_position.x
		radar_camera.global_position.z = global_position.z
		radar_camera.rotation.y = rotation.y

func add_log(message: String) -> void:
	if message.length() == 0:
		return

	if log_v_container.get_child_count() > 6:
		log_v_container.get_child(log_v_container.get_child_count() - 1).queue_free()

	var new_log : Label = log_text.duplicate()
	new_log.text = "[" + Time.get_time_string_from_system() + "] " + message
	new_log.visible = true
	log_v_container.add_child(new_log)

	await get_tree().process_frame
	log_scroll_container.scroll_vertical = log_scroll_container.get_v_scroll_bar().max_value as int

	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func(): if new_log: new_log.queue_free())
