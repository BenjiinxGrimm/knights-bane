extends CharacterBody3D

@export var move_speed: float = 5.0
@export var attack_move_penalty: float = 0.4
@export var max_hp: int = 5
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 25.0
@export var stamina_regen_delay: float = 0.8
@export var sprint_speed_mult: float = 1.6
@export var sprint_drain_rate: float = 20.0
@export var sprint_min_stamina: float = 20.0
@export var dodge_stamina_cost: float = 25.0

const GRAVITY := -20.0
const STARTUP_TIME     := 0.10
const ACTIVE_TIME      := 0.20
const RECOVERY_TIME    := 0.30
const HEAVY_STARTUP    := 0.25
const HEAVY_ACTIVE     := 0.20
const HEAVY_RECOVERY   := 0.55
const LIGHT_STAMINA_COST := 15.0
const HEAVY_STAMINA_COST := 30.0
const FLASH_DURATION   := 0.15
const IFRAMES_DURATION := 0.5
const DODGE_SPEED      := 14.0
const DODGE_DURATION   := 0.25
const DODGE_COOLDOWN   := 0.7

const HIT_PARTICLES = preload("res://scenes/hit_particles.tscn")

const COLOR_NORMAL := Color(0.55, 0.65, 0.85, 1)
const COLOR_HIT    := Color(1, 0.3, 0.3, 1)
const COLOR_DODGE  := Color(0.85, 0.92, 1.0, 1)

enum AttackState { IDLE, STARTUP, ACTIVE, RECOVERY }

var hp: int
var stamina: float
var _attack_state: AttackState = AttackState.IDLE
var _attack_timer: float = 0.0
var _flash_timer: float = 0.0
var _iframes_timer: float = 0.0
var _dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_cooldown: float = 0.0
var _dodge_dir: Vector3 = Vector3.ZERO
var _sprinting: bool = false
var _stamina_regen_timer: float = 0.0
var _is_heavy: bool = false
var _spawn_position: Vector3
var _material: StandardMaterial3D

@onready var _hitbox: Area3D = $AttackHitbox
@onready var _hitbox_shape: CollisionShape3D = $AttackHitbox/CollisionShape3D
@onready var _hitbox_mesh: MeshInstance3D = $AttackHitbox/DebugMesh
@onready var _mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	stamina = max_stamina
	_spawn_position = global_position
	_material = StandardMaterial3D.new()
	_material.albedo_color = COLOR_NORMAL
	_mesh.set_surface_override_material(0, _material)

func take_damage(amount: int) -> void:
	if _iframes_timer > 0.0:
		return
	hp -= amount
	_iframes_timer = IFRAMES_DURATION
	_flash_timer = FLASH_DURATION
	Effects.screenshake(0.35)
	var hit := HIT_PARTICLES.instantiate() as CPUParticles3D
	hit.position = global_position + Vector3(0, 0.5, 0)
	get_tree().current_scene.add_child(hit)
	if hp <= 0:
		Audio.play_player_death()
		_respawn()
	else:
		Audio.play_hit_player()

func _respawn() -> void:
	hp = max_hp
	stamina = max_stamina
	global_position = _spawn_position
	velocity = Vector3.ZERO
	_dodging = false
	_sprinting = false
	_attack_state = AttackState.IDLE
	_hitbox_mesh.visible = false
	print("You died — respawning")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge") and _dodge_cooldown <= 0.0 and not _dodging:
		if _attack_state != AttackState.ACTIVE and stamina >= dodge_stamina_cost:
			_start_dodge()
	if event.is_action_pressed("attack") and _attack_state == AttackState.IDLE and not _dodging:
		if stamina >= LIGHT_STAMINA_COST:
			_is_heavy = false
			_use_stamina(LIGHT_STAMINA_COST)
			_attack_state = AttackState.STARTUP
			_attack_timer = STARTUP_TIME
			Audio.play_swing_light()
	if event.is_action_pressed("heavy_attack") and _attack_state == AttackState.IDLE and not _dodging:
		if stamina >= HEAVY_STAMINA_COST:
			_is_heavy = true
			_use_stamina(HEAVY_STAMINA_COST)
			_attack_state = AttackState.STARTUP
			_attack_timer = HEAVY_STARTUP
			Audio.play_swing_heavy()

func _start_dodge() -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir.length_squared() > 0.01:
		_dodge_dir = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	else:
		_dodge_dir = transform.basis.z.normalized()
	_attack_state = AttackState.IDLE
	_hitbox_mesh.visible = false
	_use_stamina(dodge_stamina_cost)
	Audio.play_dodge()
	_dodging = true
	_dodge_timer = DODGE_DURATION
	_iframes_timer = DODGE_DURATION

func _physics_process(delta: float) -> void:
	_tick_attack(delta)
	_tick_dodge(delta)
	_tick_stamina(delta)
	_tick_timers(delta)

	if _dodging:
		velocity.x = _dodge_dir.x * DODGE_SPEED
		velocity.z = _dodge_dir.z * DODGE_SPEED
	else:
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
		elif _sprinting:
			speed_mult = sprint_speed_mult

		velocity.x = direction.x * move_speed * speed_mult
		velocity.z = direction.z * move_speed * speed_mult

	if not _dodging and _attack_state != AttackState.ACTIVE:
		_rotate_toward_mouse()

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()

func _tick_stamina(delta: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length_squared() > 0.1
	_sprinting = Input.is_action_pressed("sprint") and moving and stamina >= sprint_min_stamina and not _dodging

	if _sprinting:
		_use_stamina(sprint_drain_rate * delta)

	if _stamina_regen_timer > 0.0:
		_stamina_regen_timer -= delta
	elif stamina < max_stamina:
		stamina = minf(stamina + stamina_regen_rate * delta, max_stamina)

func _use_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	_stamina_regen_timer = stamina_regen_delay

func _tick_dodge(delta: float) -> void:
	if _dodge_cooldown > 0.0:
		_dodge_cooldown -= delta
	if not _dodging:
		return
	_dodge_timer -= delta
	if _dodge_timer <= 0.0:
		_dodging = false
		_dodge_cooldown = DODGE_COOLDOWN

func _tick_timers(delta: float) -> void:
	if _iframes_timer > 0.0:
		_iframes_timer -= delta
	if _flash_timer > 0.0:
		_flash_timer -= delta
	if _dodging:
		_material.albedo_color = COLOR_DODGE
	elif _flash_timer > 0.0:
		_material.albedo_color = COLOR_HIT
	else:
		_material.albedo_color = COLOR_NORMAL

func _tick_attack(delta: float) -> void:
	if _attack_state == AttackState.IDLE:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	match _attack_state:
		AttackState.STARTUP:
			_attack_state = AttackState.ACTIVE
			_attack_timer = HEAVY_ACTIVE if _is_heavy else ACTIVE_TIME
			_hitbox_mesh.visible = true
			if _is_heavy:
				Effects.zoom_punch(2.0)
			_do_attack()
		AttackState.ACTIVE:
			_attack_state = AttackState.RECOVERY
			_attack_timer = HEAVY_RECOVERY if _is_heavy else RECOVERY_TIME
			_hitbox_mesh.visible = false
		AttackState.RECOVERY:
			_attack_state = AttackState.IDLE

func _do_attack() -> void:
	var damage := 2 if _is_heavy else 1
	var knock_mult := 2.0 if _is_heavy else 1.0
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
			if _is_heavy:
				Effects.hitstop(0.15)
				Effects.screenshake(0.25)
			var knock_dir := (body.global_position - global_position).normalized()
			body.call("take_damage", damage, knock_dir, knock_mult)

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
