extends Control

class_name RoomScreenController

signal interaction_requested(interaction_id: String)
signal continue_requested

const DESIGN_SIZE: Vector2 = Vector2(1600.0, 900.0)
const HOTSPOT_AVAILABLE_COLOR: Color = Color(0.98, 0.72, 0.22, 0.42)
const HOTSPOT_USED_COLOR: Color = Color(0.24, 0.27, 0.28, 0.5)

@onready var round_value_label: Label = %RoundValueLabel
@onready var gold_value_label: Label = %GoldValueLabel
@onready var core_hp_value_label: Label = %CoreHPValueLabel
@onready var message_label: Label = %RoomMessageLabel
@onready var interaction_buttons: Array[Button] = [
	%InteractionButton1,
	%InteractionButton2,
	%InteractionButton3
]
@onready var hotspot_buttons: Dictionary = {
	"llamar_madre": %PhoneHotspotButton,
	"buscar_monedas_pantalon": %PantsHotspotButton,
	"reiniciar_router": %RouterHotspotButton
}
@onready var hotspot_frames: Dictionary = {
	"llamar_madre": %PhoneHotspotFrame,
	"buscar_monedas_pantalon": %PantsHotspotFrame,
	"reiniciar_router": %RouterHotspotFrame
}

var _interaction_ids: Array[String] = []
const HOTSPOT_TEXT: Dictionary = {
	"llamar_madre": "Telefono / puerta - Llamar",
	"buscar_monedas_pantalon": "Pantalon - monedas",
	"reiniciar_router": "Router - reiniciar"
}

func _ready() -> void:
	_fit_design_canvas_to_viewport()
	get_viewport().size_changed.connect(_fit_design_canvas_to_viewport)
	for i: int in range(interaction_buttons.size()):
		interaction_buttons[i].pressed.connect(_on_interaction_button_pressed.bind(i))
	for interaction_id: String in hotspot_buttons.keys():
		var button: Button = hotspot_buttons[interaction_id]
		button.pressed.connect(request_interaction.bind(interaction_id))

func show_room() -> void:
	_fit_design_canvas_to_viewport()
	visible = true

func get_designed_content_rect() -> Rect2:
	return Rect2(position, DESIGN_SIZE * scale)

func set_status(round_value: int, gold_value: int, core_hp_value: int) -> void:
	round_value_label.text = str(round_value)
	gold_value_label.text = str(gold_value)
	core_hp_value_label.text = str(core_hp_value)

func set_interactions(interaction_data: Array[Dictionary]) -> void:
	_interaction_ids.clear()
	for i: int in range(interaction_buttons.size()):
		var button: Button = interaction_buttons[i]
		if i >= interaction_data.size():
			button.text = "N/A"
			button.disabled = true
			_interaction_ids.append("")
			continue
		var data: Dictionary = interaction_data[i]
		var interaction_id: String = String(data.get("id", ""))
		var is_used: bool = bool(data.get("used", false))
		var status_text: String = "USADO" if is_used else "DISPONIBLE"
		button.text = "%s\n%s\n%s" % [
			String(data.get("name", interaction_id)).capitalize(),
			String(data.get("effect", "")),
			status_text
		]
		button.disabled = is_used or interaction_id.is_empty()
		_interaction_ids.append(interaction_id)
		_update_hotspot(interaction_id, is_used)

func set_message(message: String) -> void:
	if message_label == null:
		return
	message_label.text = message

func request_interaction(interaction_id: String) -> void:
	interaction_requested.emit(interaction_id)

func request_continue() -> void:
	continue_requested.emit()

func _on_interaction_button_pressed(index: int) -> void:
	if index < 0 or index >= _interaction_ids.size():
		return
	var interaction_id: String = _interaction_ids[index]
	if interaction_id.is_empty():
		return
	request_interaction(interaction_id)

func _update_hotspot(interaction_id: String, is_used: bool) -> void:
	if not hotspot_buttons.has(interaction_id):
		return
	var hotspot: Button = hotspot_buttons[interaction_id]
	hotspot.disabled = is_used
	hotspot.text = "USADO" if is_used else String(HOTSPOT_TEXT.get(interaction_id, interaction_id))
	hotspot.modulate = Color(0.62, 0.62, 0.62, 1.0) if is_used else Color.WHITE
	if hotspot_frames.has(interaction_id):
		var frame: ColorRect = hotspot_frames[interaction_id]
		frame.color = HOTSPOT_USED_COLOR if is_used else HOTSPOT_AVAILABLE_COLOR

func _fit_design_canvas_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = min(1.0, viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	if fit_scale <= 0.0:
		fit_scale = 1.0
	set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	scale = Vector2(fit_scale, fit_scale)
	size = DESIGN_SIZE
	position = Vector2.ZERO
