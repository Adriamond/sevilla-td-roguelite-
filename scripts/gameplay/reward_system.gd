extends Node

class_name RewardSystem

signal rewards_generated(item_ids: Array[String])
signal reward_selected(item_id: String)

const REWARD_OPTIONS: int = 3

func generate_rewards() -> Array[String]:
    # TODO: Implement tag-based reward pool and stabilizer logic.
    var rewards: Array[String] = []
    rewards_generated.emit(rewards)
    return rewards

func select_reward(item_id: String) -> void:
    RunState.picked_item_ids.append(item_id)
    reward_selected.emit(item_id)
