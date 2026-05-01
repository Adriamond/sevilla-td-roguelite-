extends Control

class_name RoomScreenController

signal interaction_requested(interaction_id: String)
signal continue_requested

func show_room() -> void:
    visible = true

func request_interaction(interaction_id: String) -> void:
    interaction_requested.emit(interaction_id)

func request_continue() -> void:
    continue_requested.emit()
