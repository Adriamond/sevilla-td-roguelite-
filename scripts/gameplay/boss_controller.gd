extends Node

class_name BossController

signal boss_phase_changed(phase_index: int)
signal boss_defeated

var current_phase: int = 0

func start_boss() -> void:
    current_phase = 1
    boss_phase_changed.emit(current_phase)

func set_phase(phase_index: int) -> void:
    current_phase = phase_index
    boss_phase_changed.emit(current_phase)

func defeat_boss() -> void:
    boss_defeated.emit()
