extends Node2D

class_name DefenseActor

signal defense_clicked(defense: DefenseActor)

const MAX_LEVEL: int = 2
const UPGRADE_COST: int = 45

var defense_id: String = ""
var damage: float = 1.0
var attack_range: float = 64.0
var fire_rate: float = 1.0
var targeting_mode: String = "first"
var base_cost: int = 0
var level: int = 1
var total_invested_cost: int = 0
var has_participated_in_wave: bool = false

var _cooldown: float = 0.0
var _wave_controller: WaveController = null

@onready var label: Label = get_node_or_null("%DefenseLabel")
@onready var range_circle: Line2D = get_node_or_null("%RangeCircle")
@onready var attack_beam: Line2D = get_node_or_null("%AttackBeam")
@onready var click_area: Area2D = get_node_or_null("%ClickArea")
@onready var body_polygon: Polygon2D = get_node_or_null("%Body")

var _beam_timer: float = 0.0

func setup_from_def(defense_def: Resource, wave_controller: WaveController) -> void:
	defense_id = String(defense_def.get("id"))
	base_cost = int(defense_def.get("base_cost"))
	level = 1
	total_invested_cost = base_cost
	damage = float(defense_def.get("base_damage"))
	attack_range = float(defense_def.get("base_range"))
	fire_rate = max(float(defense_def.get("base_fire_rate")), 0.1)
	targeting_mode = String(defense_def.get("targeting_mode"))
	has_participated_in_wave = false
	_wave_controller = wave_controller

	if label != null:
		label.text = defense_id
	_apply_visual_profile()
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

func mark_participated_in_wave() -> void:
	has_participated_in_wave = true

func can_upgrade() -> bool:
	return level < MAX_LEVEL

func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0
	return UPGRADE_COST

func apply_upgrade() -> bool:
	if not can_upgrade():
		return false
	level += 1
	damage *= 1.5
	total_invested_cost += UPGRADE_COST
	return true

func _apply_visual_profile() -> void:
	if defense_id == "cable_pelao":
		if body_polygon != null:
			body_polygon.color = Color(0.98, 0.83, 0.22, 1.0)
		if range_circle != null:
			range_circle.default_color = Color(0.98, 0.83, 0.22, 0.24)
		if attack_beam != null:
			attack_beam.default_color = Color(1.0, 0.92, 0.38, 0.95)
	else:
		if body_polygon != null:
			body_polygon.color = Color(0.16, 0.78, 1.0, 1.0)
		if range_circle != null:
			range_circle.default_color = Color(0.3, 0.85, 1.0, 0.24)
		if attack_beam != null:
			attack_beam.default_color = Color(0.46, 0.95, 1.0, 0.95)
