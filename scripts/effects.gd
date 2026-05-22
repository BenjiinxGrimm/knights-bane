extends Node

signal shake_requested(intensity: float)
signal zoom_requested(amount: float)

var _hitstop_end_ms: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func hitstop(duration_sec: float) -> void:
	var end_ms := Time.get_ticks_msec() + int(duration_sec * 1000.0)
	if end_ms > _hitstop_end_ms:
		Engine.time_scale = 0.0
		_hitstop_end_ms = end_ms

func screenshake(intensity: float) -> void:
	shake_requested.emit(intensity)

func zoom_punch(amount: float) -> void:
	zoom_requested.emit(amount)

func _process(_delta: float) -> void:
	if Engine.time_scale == 0.0 and Time.get_ticks_msec() >= _hitstop_end_ms:
		Engine.time_scale = 1.0
