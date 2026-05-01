extends Control

class_name EndScreenController

signal back_to_menu_requested

func request_back_to_menu() -> void:
    back_to_menu_requested.emit()
