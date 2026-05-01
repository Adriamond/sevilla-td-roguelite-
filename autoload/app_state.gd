extends Node

enum AppMode {
    BOOT,
    MAIN_MENU,
    ROOM,
    GAMEPLAY,
    PAUSED,
    VICTORY,
    DEFEAT
}

var current_mode: AppMode = AppMode.BOOT

func set_mode(new_mode: AppMode) -> void:
    current_mode = new_mode

func is_gameplay_mode() -> bool:
    return current_mode == AppMode.GAMEPLAY
