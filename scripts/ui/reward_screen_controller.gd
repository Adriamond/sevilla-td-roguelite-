extends Control

class_name RewardScreenController

signal reward_chosen(item_id: String)

@onready var reward_buttons: Array[Button] = [
    %RewardButton1,
    %RewardButton2,
    %RewardButton3
]

var _current_item_ids: Array[String] = []

func _ready() -> void:
    reward_buttons[0].pressed.connect(_on_reward_button_pressed.bind(0))
    reward_buttons[1].pressed.connect(_on_reward_button_pressed.bind(1))
    reward_buttons[2].pressed.connect(_on_reward_button_pressed.bind(2))

func show_rewards(item_ids: Array[String]) -> void:
    _current_item_ids = item_ids.duplicate()
    while _current_item_ids.size() < reward_buttons.size():
        _current_item_ids.append("")

    for i: int in range(reward_buttons.size()):
        var item_id: String = _current_item_ids[i]
        var button: Button = reward_buttons[i]
        button.disabled = item_id.is_empty()
        button.text = item_id if not item_id.is_empty() else "N/A"

func choose_reward(item_id: String) -> void:
    reward_chosen.emit(item_id)

func _on_reward_button_pressed(index: int) -> void:
    if index < 0 or index >= _current_item_ids.size():
        return
    var item_id: String = _current_item_ids[index]
    if item_id.is_empty():
        return
    choose_reward(item_id)
