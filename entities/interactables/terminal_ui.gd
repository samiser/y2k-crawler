extends Window

signal closed

func _ready() -> void:
	hide()
	close_requested.connect(_on_close)

func _on_close() -> void:
	hide()
	closed.emit()
