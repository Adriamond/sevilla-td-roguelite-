extends Area2D

class_name BuildPad

signal pad_clicked(pad: BuildPad)

@export var pad_category: String = "ground"
@export var pad_id: String = ""

func _ready() -> void:
	input_pickable = true

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_event.pressed:
		return
	pad_clicked.emit(self)
