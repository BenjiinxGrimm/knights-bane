extends CharacterBody3D

@export var move_speed: float = 5.0

const GRAVITY := -20.0
const ROTATION_SPEED := 10.0  # How fast the character snaps to face its direction

func _physics_process(delta: float) -> void:
	# get_axis returns -1 when the negative action is held, +1 for positive
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	# Without this, diagonal input would have length ~1.41 (faster than cardinal)
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	# In Godot, -Z is "forward" into the world from a top-down camera
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	# Rotate the character to face wherever it's moving
	if direction.length_squared() > 0.01:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)

	# Gravity — only accumulates when airborne so landing feels snappy
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	move_and_slide()
