extends RefCounted

class_name TargetingService

static func pick_target(candidates: Array[Node], mode: String) -> Node:
    if candidates.is_empty():
        return null

    match mode:
        "first":
            return candidates[0]
        "last":
            return candidates[candidates.size() - 1]
        "strongest":
            return _pick_strongest(candidates)
        _:
            return candidates[0]

static func _pick_strongest(candidates: Array[Node]) -> Node:
    var selected: Node = candidates[0]
    # TODO: Compare enemy hp when enemy implementation exists.
    return selected
