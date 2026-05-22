extends Camera3D

@export var target: Node3D
@export var camera_offset: Vector3 = Vector3(0, 10, 8)
@export var follow_speed: float = 5.0

var _shake_intensity: float = 0.0
var _zoom_amount: float = 0.0

func _ready() -> void:
	Effects.shake_requested.connect(_on_shake_requested)
	Effects.zoom_requested.connect(_on_zoom_requested)

func _on_shake_requested(intensity: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)

func _on_zoom_requested(amount: float) -> void:
	_zoom_amount = maxf(_zoom_amount, amount)

func _process(delta: float) -> void:
	if not target:
		return
	var zoomed_offset := camera_offset * (1.0 - _zoom_amount * 0.07)
	_zoom_amount = lerpf(_zoom_amount, 0.0, delta * 8.0)
	var goal := target.global_position + zoomed_offset
	var next_pos := global_position.lerp(goal, follow_speed * delta)
	if _shake_intensity > 0.005:
		next_pos += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * _shake_intensity
		_shake_intensity = lerpf(_shake_intensity, 0.0, delta * 12.0)
	else:
		_shake_intensity = 0.0
	global_position = next_pos
	look_at(target.global_position, Vector3.UP)
