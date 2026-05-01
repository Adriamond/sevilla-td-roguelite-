extends RefCounted

class_name WeightedTable

var entries: Array = []

func add_entry(id: String, weight: float) -> void:
    if weight <= 0.0:
        return
    entries.append({
        "id": id,
        "weight": weight
    })

func is_empty() -> bool:
    return entries.is_empty()

func pick(rng: RandomNumberGenerator) -> String:
    var total_weight: float = 0.0
    for entry in entries:
        total_weight += float(entry["weight"])

    if total_weight <= 0.0:
        return ""

    var roll: float = rng.randf() * total_weight
    var cursor: float = 0.0

    for entry in entries:
        cursor += float(entry["weight"])
        if roll <= cursor:
            return String(entry["id"])

    return String(entries.back()["id"])
