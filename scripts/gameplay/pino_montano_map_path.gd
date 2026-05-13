extends Node2D

const MAIN_ROUTE_POINTS: Array[Vector2] = [
	Vector2(160, 1260),
	Vector2(520, 1260),
	Vector2(520, 1000),
	Vector2(1020, 1000),
	Vector2(1020, 760),
	Vector2(620, 760),
	Vector2(620, 500),
	Vector2(1420, 500),
	Vector2(1420, 260),
	Vector2(2200, 260),
	Vector2(2200, 650),
	Vector2(2820, 650),
	Vector2(2820, 250)
]

const FALLBACK_MAP_BOUNDS: Rect2 = Rect2(Vector2.ZERO, Vector2(3000.0, 1450.0))

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

func get_map_bounds() -> Rect2:
	var background: Polygon2D = get_node_or_null("Background") as Polygon2D
	if background != null and background.polygon.size() >= 3:
		return _points_rect(background.polygon)

	var bounds: Rect2 = _points_rect(PackedVector2Array(MAIN_ROUTE_POINTS))
	if bounds.size.x > 0.0 and bounds.size.y > 0.0:
		return bounds.grow(40.0)
	return FALLBACK_MAP_BOUNDS

func _polyline_length(points: PackedVector2Array) -> float:
	if points.size() < 2:
		return 0.0
	var total: float = 0.0
	for i: int in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

func _points_rect(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point: Vector2 in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)
