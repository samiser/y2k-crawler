extends Window

signal closed
signal end_game

@onready var cancel_button: Button = %CancelButton
@onready var ok_button: Button = %OkButton

func _ready() -> void:
	add_to_group("ui_window")
	hide()
	close_requested.connect(_on_close)
	cancel_button.pressed.connect(_on_close)
	ok_button.pressed.connect(func() -> void: 
		_on_close() 
		end_game.emit()
	)

func _on_close() -> void:
	closed.emit()
	hide()
