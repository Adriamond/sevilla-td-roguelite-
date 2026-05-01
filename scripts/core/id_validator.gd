extends RefCounted

class_name IdValidator

static func is_valid_id(id: String) -> bool:
    if id.is_empty():
        return false
    var regex := RegEx.new()
    regex.compile("^[a-z0-9_]+$")
    return regex.search(id) != null

static func find_duplicate_ids(ids: Array[String]) -> Array[String]:
    var seen: Dictionary = {}
    var duplicates: Array[String] = []

    for id in ids:
        if seen.has(id):
            if not duplicates.has(id):
                duplicates.append(id)
        else:
            seen[id] = true

    return duplicates
