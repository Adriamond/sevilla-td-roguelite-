extends RefCounted

class_name TagQuery

static func has_tag(tags: PackedStringArray, tag: String) -> bool:
    return tags.has(tag)

static func has_any(tags: PackedStringArray, required_tags: PackedStringArray) -> bool:
    for tag in required_tags:
        if tags.has(tag):
            return true
    return false

static func has_all(tags: PackedStringArray, required_tags: PackedStringArray) -> bool:
    for tag in required_tags:
        if not tags.has(tag):
            return false
    return true
