extends Control

class_name GameplayRootController

signal start_dummy_wave_requested
signal complete_dummy_wave_requested

@onready var phase_label: Label = %PhaseLabel
@onready var action_button: Button = %PhaseActionButton

var _is_wave_running: bool = false

func show_build_phase() -> void:
    _is_wave_running = false
    phase_label.text = "Build Phase (Placeholder)"
    action_button.text = "Start Dummy Wave"

func show_wave_running() -> void:
    _is_wave_running = true
    phase_label.text = "Wave Running (Placeholder)"
    action_button.text = "Complete Dummy Wave"

func request_phase_action() -> void:
    if _is_wave_running:
        complete_dummy_wave_requested.emit()
        return
    start_dummy_wave_requested.emit()
