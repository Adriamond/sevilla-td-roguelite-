extends RefCounted

class_name RunMetrics

var seed: int = 0
var character_id: String = ""
var map_id: String = ""
var victory: bool = false
var duration_seconds: float = 0.0
var picked_item_ids: Array[String] = []
var damage_by_defense: Dictionary = {}
var gold_earned: int = 0
var gold_spent: int = 0
var leaks: int = 0
var boss_time_to_kill: float = 0.0

func to_dictionary() -> Dictionary:
    return {
        "seed": seed,
        "character_id": character_id,
        "map_id": map_id,
        "victory": victory,
        "duration_seconds": duration_seconds,
        "picked_item_ids": picked_item_ids,
        "damage_by_defense": damage_by_defense,
        "gold_earned": gold_earned,
        "gold_spent": gold_spent,
        "leaks": leaks,
        "boss_time_to_kill": boss_time_to_kill
    }
