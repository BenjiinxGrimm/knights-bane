extends Node

signal shake_requested(intensity: float)

var _hitstop_end_ms: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func hitstop(duration_sec: float) -> void:
	Engine.time_scale = 0.0
	_hitstop_end_ms = Time.get_ticks_msec() + int(duration_sec * 1000.0)

func screenshake(intensity: float) -> void:
	shake_requested.emit(intensity)

func _process(_delta: float) -> void:
	if Engine.time_scale == 0.0 and Time.get_ticks_msec() >= _hitstop_end_ms:
		Engine.time_scale = 1.0
