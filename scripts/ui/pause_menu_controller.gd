extends Control

class_name PauseMenuController

signal resume_requested
signal quit_to_menu_requested

func request_resume() -> void:
    resume_requested.emit()

func request_quit_to_menu() -> void:
    quit_to_menu_requested.emit()
