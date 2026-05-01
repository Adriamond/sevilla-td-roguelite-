extends Node

class_name EconomySystem

func get_round_reward(round_index: int) -> int:
    return 45 + 15 * round_index

func get_sell_multiplier(round_index: int) -> float:
    return 0.8 if round_index <= 2 else 0.7

func get_upgrade_cost(base_cost: int, level: int) -> int:
    var multipliers: Array[float] = [1.0, 1.6, 2.2]
    var index: int = clamp(level, 0, multipliers.size() - 1)
    return int(round(base_cost * multipliers[index]))
