extends CharacterBody3D

@export var move_speed: float = 5.0
@export var attack_move_penalty: float = 0.4

const GRAVITY := -20.0
const ROTATION_SPEED := 10.0

const STARTUP_TIME  := 0.10
const ACTIVE_TIME   := 0.20
const RECOVERY_TIME := 0.30

enum AttackState { IDLE, STARTUP, ACTIVE, RECOVERY }

var _attack_state: AttackState = AttackState.IDLE
var _attack_timer: float = 0.0

@onready var _hitbox: Area3D = $AttackHitbox
@onready var _hitbox_shape: CollisionShape3D = $AttackHitbox/CollisionShape3D
@onready var _hitbox_mesh: MeshInstance3D = $AttackHitbox/DebugMesh

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and _attack_state == AttackState.IDLE:
		_attack_state = AttackState.STARTUP
		_attack_timer = STARTUP_TIME

func _physics_process(delta: float) -> void:
	_tick_attack(delta)

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	var direction := Vector3(input_dir.x, 0.0, input_dir.y)

	var speed_mult := 1.0
	if _attack_state == AttackState.STARTUP or _attack_state == AttackState.ACTIVE:
		speed_mult = attack_move_penalty

	velocity.x = direction.x * move_speed * speed_mult
	velocity.z = direction.z * move_speed * speed_mult

	if _attack_state != AttackState.ACTIVE:
		_rotate_toward_mouse()

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	move_and_slide()

func _tick_attack(delta: float) -> void:
	if _attack_state == AttackState.IDLE:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	match _attack_state:
		AttackState.STARTUP:
			_attack_state = AttackState.ACTIVE
			_attack_timer = ACTIVE_TIME
			_hitbox_mesh.visible = true
			_do_attack()
		AttackState.ACTIVE:
			_attack_state = AttackState.RECOVERY
			_attack_timer = RECOVERY_TIME
			_hitbox_mesh.visible = false
		AttackState.RECOVERY:
			_attack_state = AttackState.IDLE

func _do_attack() -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _hitbox_shape.shape
	query.transform = _hitbox.global_transform
	query.collision_mask = 1
	query.exclude = [get_rid()]
	for hit in space.intersect_shape(query, 8):
		var body := hit["collider"] as Node3D
		if body == null or not body.is_in_group("enemy"):
			continue
		if body.has_method("take_damage"):
			var knock_dir := (body.global_position - global_position).normalized()
			body.call("take_damage", 1, knock_dir)

func _rotate_toward_mouse() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	if abs(ray_dir.y) < 0.001:
		return
	var t := (global_position.y - ray_origin.y) / ray_dir.y
	if t < 0.0:
		return
	var world_point := ray_origin + ray_dir * t
	var look_dir := world_point - global_position
	look_dir.y = 0.0
	if look_dir.length_squared() > 0.01:
		rotation.y = atan2(-look_dir.x, -look_dir.z)
