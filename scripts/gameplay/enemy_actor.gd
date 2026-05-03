extends Node2D

class_name EnemyActor

signal reached_end(enemy_id: String, leak_damage: int)
signal removed_from_wave(enemy_id: String)
signal died(enemy_id: String, gold_reward: int, world_position: Vector2)

const SPEED_SCALE: float = 95.0

var enemy_id: String = ""
var hp: float = 1.0
var current_hp: float = 1.0
var speed: float = 1.0
var leak_damage: int = 1
var gold_reward: int = 0
var _is_boss: bool = false

var _path: Path2D = null
var _distance_travelled: float = 0.0
var _path_length: float = 0.0
var _path_points: PackedVector2Array = PackedVector2Array()
var _already_reached_end: bool = false
var _death_processed: bool = false

@onready var type_label: Label = get_node_or_null("%TypeLabel")
@onready var body_polygon: Polygon2D = get_node_or_null("%Body")
@onready var health_bar: ProgressBar = get_node_or_null("%HealthBar")
@onready var hit_label: Label = get_node_or_null("%HitLabel")

var _default_body_color: Color = Color(1, 0.22, 0.35, 1)
var _hit_flash_timer: float = 0.0
var _hit_label_timer: float = 0.0
var _hit_label_start_position: Vector2 = Vector2.ZERO

func setup_from_def(enemy_def: Resource, path: Path2D, is_elite: bool = false) -> void:
	enemy_id = String(enemy_def.get("id"))
	hp = float(enemy_def.get("base_hp"))
	current_hp = hp
	speed = float(enemy_def.get("base_speed"))
	leak_damage = int(enemy_def.get("leak_damage"))
	gold_reward = int(enemy_def.get("gold_reward"))
	_is_boss = bool(enemy_def.get("is_boss"))
	_death_processed = false

	if is_elite:
		hp *= 2.2
		current_hp = hp
		scale = Vector2(1.25, 1.25)
	if _is_boss:
		scale = Vector2(1.65, 1.65)

	_path = path
	_distance_travelled = 0.0
	_path_points = _build_path_points(_path)
	_path_length = _compute_polyline_length(_path_points)
	if _path_length <= 0.0:
		push_warning("EnemyActor path length is zero for enemy_id=%s." % enemy_id)
	z_index = 50
	if type_label != null:
		var label_prefix: String = "BOSS " if _is_boss else ""
		type_label.text = "%s%s 0%%" % [label_prefix, _short_enemy_id(enemy_id)]
	if body_polygon != null:
		if _is_boss:
			body_polygon.color = Color(0.62, 0.2, 0.92, 1.0)
		_default_body_color = body_polygon.color
	if health_bar != null:
		health_bar.max_value = hp
		health_bar.value = current_hp
	if hit_label != null:
		_hit_label_start_position = hit_label.position
	_update_position()

func _process(delta: float) -> void:
	if _path == null:
		return
	if _path_length <= 0.0:
		return
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = max(0.0, _hit_flash_timer - delta)
		if _hit_flash_timer <= 0.0 and body_polygon != null:
			body_polygon.color = _default_body_color
	if _hit_label_timer > 0.0:
		_hit_label_timer = max(0.0, _hit_label_timer - delta)
		if hit_label != null:
			var ratio: float = _hit_label_timer / 0.28
			hit_label.position = _hit_label_start_position + Vector2(0.0, -12.0 * (1.0 - clamp(ratio, 0.0, 1.0)))
		if _hit_label_timer <= 0.0 and hit_label != null:
			hit_label.visible = false
			hit_label.position = _hit_label_start_position

	_distance_travelled += max(speed, 0.0) * SPEED_SCALE * delta
	if _distance_travelled >= _path_length:
		if not _already_reached_end:
			_already_reached_end = true
			reached_end.emit(enemy_id, leak_damage)
		queue_free()
		return

	_update_position()

func _update_position() -> void:
	if _path == null:
		return
	if _path_points.size() < 2:
		return
	var local_point: Vector2 = _sample_polyline(_path_points, _distance_travelled)
	global_position = _path.to_global(local_point)
	if type_label != null and _path_length > 0.0:
		var progress_pct: int = int((_distance_travelled / _path_length) * 100.0)
		var label_prefix: String = "BOSS " if _is_boss else ""
		type_label.text = "%s%s %d%%" % [label_prefix, _short_enemy_id(enemy_id), clamp(progress_pct, 0, 99)]

func _exit_tree() -> void:
	removed_from_wave.emit(enemy_id)

func apply_damage(amount: float, is_crit: bool = false) -> bool:
	if _death_processed:
		return false
	if amount <= 0.0:
		return false
	current_hp = max(0.0, current_hp - amount)
	if health_bar != null:
		health_bar.max_value = hp
		health_bar.value = current_hp
	if body_polygon != null:
		body_polygon.color = Color(1.0, 1.0, 1.0, 1.0)
		_hit_flash_timer = 0.08
	if hit_label != null:
		hit_label.text = "CRIT -%.1f" % amount if is_crit else "-%.1f" % amount
		hit_label.visible = true
		_hit_label_timer = 0.22
	if current_hp > 0.0:
		return false
	_begin_death()
	return true

func is_alive() -> bool:
	return current_hp > 0.0 and not _already_reached_end

func get_progress_ratio() -> float:
	if _path_length <= 0.0:
		return 0.0
	return clamp(_distance_travelled / _path_length, 0.0, 1.0)

func _begin_death() -> void:
	if _death_processed or _already_reached_end:
		return
	_death_processed = true
	died.emit(enemy_id, gold_reward, global_position)
	if hit_label != null:
		hit_label.text = "KO +%dg" % max(0, gold_reward)
		hit_label.visible = true
		_hit_label_timer = 0.28
	call_deferred("_queue_free_after_feedback")

func _queue_free_after_feedback() -> void:
	if not is_inside_tree():
		queue_free()
		return
	await get_tree().create_timer(0.16).timeout
	queue_free()

func _short_enemy_id(value: String) -> String:
	if value.is_empty():
		return "enemy"
	var parts: PackedStringArray = value.split("_")
	if parts.is_empty():
		return value
	return parts[0].substr(0, min(6, parts[0].length()))

func _build_path_points(path: Path2D) -> PackedVector2Array:
	if path == null or path.curve == null:
		return PackedVector2Array()

	var curve: Curve2D = path.curve
	var baked_points: PackedVector2Array = curve.get_baked_points()
	if baked_points.size() >= 2 and _compute_polyline_length(baked_points) > 0.1:
		return baked_points

	var control_points: PackedVector2Array = PackedVector2Array()
	var point_count: int = curve.get_point_count()
	for i: int in range(point_count):
		control_points.append(curve.get_point_position(i))
	if control_points.size() >= 2 and _compute_polyline_length(control_points) > 0.1:
		return control_points

	var path_visual: Line2D = path.get_parent().get_node_or_null("PathVisual")
	if path_visual != null:
		var visual_points: PackedVector2Array = path_visual.points
		if visual_points.size() >= 2 and _compute_polyline_length(visual_points) > 0.1:
			return visual_points

	return PackedVector2Array()

func _compute_polyline_length(points: PackedVector2Array) -> float:
	if points.size() < 2:
		return 0.0
	var total: float = 0.0
	for i: int in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

func _sample_polyline(points: PackedVector2Array, distance: float) -> Vector2:
	if points.size() == 0:
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]

	var remaining: float = max(distance, 0.0)
	for i: int in range(points.size() - 1):
		var from_point: Vector2 = points[i]
		var to_point: Vector2 = points[i + 1]
		var segment_length: float = from_point.distance_to(to_point)
		if segment_length <= 0.0001:
			continue
		if remaining <= segment_length:
			var t: float = remaining / segment_length
			return from_point.lerp(to_point, t)
		remaining -= segment_length

	return points[points.size() - 1]
