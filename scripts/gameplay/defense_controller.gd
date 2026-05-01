extends Node

class_name DefenseController

signal defense_built(defense_id: String)
signal defense_sold(defense_id: String)
signal defense_upgraded(defense_id: String, level: int)

func can_build(defense_id: String, pad_category: String) -> bool:
    # TODO: Validate defense category against pad category.
    _ = defense_id
    _ = pad_category
    return true

func build_defense(defense_id: String, pad: Node) -> bool:
    # TODO: Spend gold and instantiate defense.
    _ = pad
    defense_built.emit(defense_id)
    return true

func sell_defense(defense_node: Node) -> void:
    # TODO: Refund gold and remove defense.
    _ = defense_node

func upgrade_defense(defense_node: Node) -> bool:
    # TODO: Spend gold and upgrade defense.
    _ = defense_node
    return true
