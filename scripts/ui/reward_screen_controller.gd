extends Control

class_name RewardScreenController

signal reward_chosen(item_id: String)

func show_rewards(item_ids: Array[String]) -> void:
    # TODO: Render reward cards.
    _ = item_ids

func choose_reward(item_id: String) -> void:
    reward_chosen.emit(item_id)
