extends Control

class_name RoomScreenController

signal interaction_requested(interaction_id: String)
signal continue_requested

@onready var round_value_label: Label = %RoundValueLabel
@onready var gold_value_label: Label = %GoldValueLabel
@onready var core_hp_value_label: Label = %CoreHPValueLabel

func show_room() -> void:
    visible = true

func set_status(round_value: int, gold_value: int, core_hp_value: int) -> void:
    round_value_label.text = str(round_value)
    gold_value_label.text = str(gold_value)
    core_hp_value_label.text = str(core_hp_value)

func request_interaction(interaction_id: String) -> void:
    interaction_requested.emit(interaction_id)

func request_continue() -> void:
    continue_requested.emit()
