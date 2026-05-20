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
@onready var _hitbox_mesh: MeshInstance3D = $AttackHitbox/DebugMesh

func _ready() -> void:
	_hitbox.body_entered.connect(_on_hitbox_body_entered)

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

	# Lock facing direction during the active window so the swing commits
	if _attack_state != AttackState.ACTIVE and direction.length_squared() > 0.01:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)

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
			_hitbox.monitoring = true
			_hitbox_mesh.visible = true
		AttackState.ACTIVE:
			_attack_state = AttackState.RECOVERY
			_attack_timer = RECOVERY_TIME
			_hitbox.monitoring = false
			_hitbox_mesh.visible = false
		AttackState.RECOVERY:
			_attack_state = AttackState.IDLE

func _on_hitbox_body_entered(body: Node3D) -> void:
	print("Hit: ", body.name)
