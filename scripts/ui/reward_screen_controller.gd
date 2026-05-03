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
        button.text = _build_card_text(item_id) if not item_id.is_empty() else "N/A"

func choose_reward(item_id: String) -> void:
    reward_chosen.emit(item_id)

func _on_reward_button_pressed(index: int) -> void:
    if index < 0 or index >= _current_item_ids.size():
        return
    var item_id: String = _current_item_ids[index]
    if item_id.is_empty():
        return
    choose_reward(item_id)

func _build_card_text(item_id: String) -> String:
    var item_def: Resource = get_node("/root/ContentDB").call("get_item", item_id)
    if item_def == null:
        return item_id
    var title: String = String(item_def.get("display_name_es")).strip_edges()
    if title.is_empty():
        title = String(item_def.get("display_name")).strip_edges()
    if title.is_empty():
        title = item_id
    var effect_text: String = _get_effect_text(item_id, item_def)
    var flavor_text: String = String(item_def.get("flavor_text_es")).strip_edges()
    if flavor_text.is_empty():
        flavor_text = String(item_def.get("description_es")).strip_edges()
    if flavor_text.is_empty():
        flavor_text = String(item_def.get("description")).strip_edges()
    var lines: Array[String] = []
    lines.append(title.capitalize())
    lines.append("")
    lines.append(effect_text)
    if not flavor_text.is_empty():
        lines.append("")
        lines.append(flavor_text)
    lines.append("")
    lines.append("[id: %s]" % item_id)
    return "\n".join(lines)

func _get_effect_text(item_id: String, item_def: Resource) -> String:
    match item_id:
        "litrito":
            return "+10% rango de torretas\n+10% probabilidad critica"
        "media_bellota":
            return "+30 oro"
        "rasta":
            return "+10 Core HP"
        _:
            var description_es: String = String(item_def.get("description_es")).strip_edges()
            if not description_es.is_empty():
                return description_es
            var description: String = String(item_def.get("description")).strip_edges()
            return description if not description.is_empty() else "Efecto MVP"
