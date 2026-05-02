extends Node2D

const MAIN_ROUTE_POINTS: Array[Vector2] = [
	Vector2(70, 480),
	Vector2(300, 480),
	Vector2(300, 360),
	Vector2(700, 360),
	Vector2(700, 260),
	Vector2(380, 260),
	Vector2(380, 150),
	Vector2(840, 150),
	Vector2(840, 70),
	Vector2(900, 70)
]

func _ready() -> void:
	var main_path: Path2D = get_node_or_null("MainPath")
	if main_path == null:
		return
	var curve_is_valid: bool = false
	if main_path.curve != null and main_path.curve.get_point_count() >= 2:
		var baked_points: PackedVector2Array = main_path.curve.get_baked_points()
		curve_is_valid = _polyline_length(baked_points) > 0.1
	if curve_is_valid:
		return

	var curve: Curve2D = Curve2D.new()
	for point: Vector2 in MAIN_ROUTE_POINTS:
		curve.add_point(point)
	main_path.curve = curve

func _polyline_length(points: PackedVector2Array) -> float:
	if points.size() < 2:
		return 0.0
	var total: float = 0.0
	for i: int in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total
