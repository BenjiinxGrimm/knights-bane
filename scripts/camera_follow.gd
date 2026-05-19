extends Camera3D

# Drag the Player node into this slot in the Inspector
@export var target: Node3D

# (0, 10, 8) = 10 units above, 8 units behind the player — Hades-style angle
# Increase Y for more top-down; increase Z to pull the camera further back
@export var camera_offset: Vector3 = Vector3(0, 10, 8)

# Higher = snappier; lower = more floaty/cinematic
@export var follow_speed: float = 5.0

func _process(delta: float) -> void:
	if not target:
		return
	var goal := target.global_position + camera_offset
	global_position = global_position.lerp(goal, follow_speed * delta)
	look_at(target.global_position, Vector3.UP)
