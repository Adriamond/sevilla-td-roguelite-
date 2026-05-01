extends Node

class_name RoomInteractionSystem

signal interaction_used(interaction_id: String)

var uses_per_run: Dictionary = {}
var uses_this_round: Dictionary = {}

func can_use(interaction_id: String) -> bool:
    # TODO: Validate costs, charges and limits.
    _ = interaction_id
    return true

func use_interaction(interaction_id: String) -> bool:
    if not can_use(interaction_id):
        return false

    # TODO: Apply interaction effects.
    uses_per_run[interaction_id] = int(uses_per_run.get(interaction_id, 0)) + 1
    uses_this_round[interaction_id] = int(uses_this_round.get(interaction_id, 0)) + 1
    interaction_used.emit(interaction_id)
    return true

func reset_round_uses() -> void:
    uses_this_round.clear()
