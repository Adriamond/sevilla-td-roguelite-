extends RefCounted

class_name TargetingService

static func pick_target(candidates: Array[Node], mode: String = "first") -> Node:
	if candidates.is_empty():
		return null

	var selected: Node = null
	match mode:
		"first":
			selected = _pick_most_progressed(candidates)
		"last":
			selected = candidates[candidates.size() - 1]
		"strongest":
			selected = _pick_highest_hp(candidates)
		_:
			selected = _pick_most_progressed(candidates)
	return selected

static func _pick_most_progressed(candidates: Array[Node]) -> Node:
	var selected: Node = candidates[0]
	var best_progress: float = _get_progress(selected)
	for candidate: Node in candidates:
		var progress: float = _get_progress(candidate)
		if progress > best_progress:
			best_progress = progress
			selected = candidate
	return selected

static func _pick_highest_hp(candidates: Array[Node]) -> Node:
	var selected: Node = candidates[0]
	var highest_hp: float = _get_hp(selected)
	for candidate: Node in candidates:
		var hp: float = _get_hp(candidate)
		if hp > highest_hp:
			highest_hp = hp
			selected = candidate
	return selected

static func _get_progress(candidate: Node) -> float:
	if candidate == null or not is_instance_valid(candidate):
		return 0.0
	if candidate.has_method("get_progress_ratio"):
		return float(candidate.call("get_progress_ratio"))
	return 0.0

static func _get_hp(candidate: Node) -> float:
	if candidate == null or not is_instance_valid(candidate):
		return 0.0
	if candidate.get("current_hp") != null:
		return float(candidate.get("current_hp"))
	return 0.0
