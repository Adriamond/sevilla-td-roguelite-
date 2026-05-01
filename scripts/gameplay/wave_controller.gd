extends Node

class_name WaveController

signal wave_started(round_index: int)
signal wave_completed(round_index: int)

var active_round_def: Resource

func start_round(round_def: Resource) -> void:
    active_round_def = round_def
    wave_started.emit(RunState.current_round)
    # TODO: Schedule WaveStepDef entries.

func complete_wave() -> void:
    wave_completed.emit(RunState.current_round)
