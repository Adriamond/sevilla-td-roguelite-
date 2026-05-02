extends Node2D

class_name EnemyActor

signal reached_end(enemy_id: String, leak_damage: int)
signal removed_from_wave(enemy_id: String)

const SPEED_SCALE: float = 95.0

var enemy_id: String = ""
var hp: float = 1.0
var speed: float = 1.0
var leak_damage: int = 1

var _path: Path2D = null
var _distance_travelled: float = 0.0
var _path_length: float = 0.0
var _path_points: PackedVector2Array = PackedVector2Array()
var _already_reached_end: bool = false

@onready var type_label: Label = get_node_or_null("%TypeLabel")

func setup_from_def(enemy_def: Resource, path: Path2D, is_elite: bool = false) -> void:
	enemy_id = String(enemy_def.get("id"))
	hp = float(enemy_def.get("base_hp"))
	speed = float(enemy_def.get("base_speed"))
	leak_damage = int(enemy_def.get("leak_damage"))

	if is_elite:
		hp *= 2.2
		scale = Vector2(1.25, 1.25)

	_path = path
	_distance_travelled = 0.0
	_path_points = _build_path_points(_path)
	_path_length = _compute_polyline_length(_path_points)
	if _path_length <= 0.0:
		push_warning("EnemyActor path length is zero for enemy_id=%s." % enemy_id)
	z_index = 50
	if type_label != null:
		type_label.text = "%s 0%%" % _short_enemy_id(enemy_id)
	_update_position()

func _process(delta: float) -> void:
	if _path == null:
		return
	if _path_length <= 0.0:
		return

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
		type_label.text = "%s %d%%" % [_short_enemy_id(enemy_id), clamp(progress_pct, 0, 99)]

func _exit_tree() -> void:
	removed_from_wave.emit(enemy_id)

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
