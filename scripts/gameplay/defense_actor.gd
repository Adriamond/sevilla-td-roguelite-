extends Node2D

class_name DefenseActor

signal defense_clicked(defense: DefenseActor)

var defense_id: String = ""
var damage: float = 1.0
var attack_range: float = 64.0
var fire_rate: float = 1.0
var targeting_mode: String = "first"
var base_cost: int = 0

var _cooldown: float = 0.0
var _wave_controller: WaveController = null

@onready var label: Label = get_node_or_null("%DefenseLabel")
@onready var range_circle: Line2D = get_node_or_null("%RangeCircle")
@onready var attack_beam: Line2D = get_node_or_null("%AttackBeam")
@onready var click_area: Area2D = get_node_or_null("%ClickArea")

var _beam_timer: float = 0.0

func setup_from_def(defense_def: Resource, wave_controller: WaveController) -> void:
	defense_id = String(defense_def.get("id"))
	base_cost = int(defense_def.get("base_cost"))
	damage = float(defense_def.get("base_damage"))
	attack_range = float(defense_def.get("base_range"))
	fire_rate = max(float(defense_def.get("base_fire_rate")), 0.1)
	targeting_mode = String(defense_def.get("targeting_mode"))
	_wave_controller = wave_controller

	if label != null:
		label.text = defense_id
	_draw_range_circle()
	if click_area != null and not click_area.is_connected("input_event", _on_click_area_input_event):
		click_area.connect("input_event", _on_click_area_input_event)

func _process(delta: float) -> void:
	if _wave_controller == null:
		return
	if _beam_timer > 0.0:
		_beam_timer = max(0.0, _beam_timer - delta)
		if _beam_timer <= 0.0 and attack_beam != null:
			attack_beam.visible = false

	_cooldown = max(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return

	var target: Node2D = _pick_target_in_range()
	if target == null:
		return

	if target.has_method("apply_damage"):
		target.call("apply_damage", damage)
	_show_attack_beam_to(target.global_position)
	_cooldown = 1.0 / fire_rate

func _pick_target_in_range() -> Node2D:
	var candidates: Array[Node] = []
	for enemy: Node in _wave_controller.get_active_enemies():
		var enemy_node: Node2D = enemy as Node2D
		if enemy_node == null:
			continue
		if global_position.distance_to(enemy_node.global_position) > attack_range:
			continue
		if enemy.has_method("is_alive") and not bool(enemy.call("is_alive")):
			continue
		candidates.append(enemy_node)

	return TargetingService.pick_target(candidates, targeting_mode) as Node2D

func _draw_range_circle() -> void:
	if range_circle == null:
		return
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 24
	for i: int in range(segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * attack_range)
	range_circle.points = points

func _show_attack_beam_to(target_global_position: Vector2) -> void:
	if attack_beam == null:
		return
	attack_beam.points = PackedVector2Array([Vector2.ZERO, to_local(target_global_position)])
	attack_beam.visible = true
	_beam_timer = 0.08

func _on_click_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_event.pressed:
		return
	defense_clicked.emit(self)
