extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_seed_value(seed_value: int) -> void:
    _rng.seed = seed_value

func random_int_range(min_value: int, max_value: int) -> int:
    return _rng.randi_range(min_value, max_value)

func random_float() -> float:
    return _rng.randf()

func pick_array(values: Array) -> Variant:
    if values.is_empty():
        return null
    return values[_rng.randi_range(0, values.size() - 1)]
