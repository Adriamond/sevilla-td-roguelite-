extends Control

class_name MainMenuController

signal start_game_requested
signal options_requested
signal quit_requested

func request_start_game() -> void:
    start_game_requested.emit()

func request_options() -> void:
    options_requested.emit()

func request_quit() -> void:
    quit_requested.emit()
