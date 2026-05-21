extends CharacterBody3D

@export var max_hp: int = 2
@export var move_speed: float = 2.0
@export var preferred_distance: float = 5.0
@export var too_close_distance: float = 3.0
@export var shoot_range: float = 9.0
@export var windup_time: float = 0.8
@export var cooldown_time: float = 2.5
@export var knockback_speed: float = 6.0

const PROJECTILE_SCENE  = preload("res://scenes/projectile.tscn")
const HIT_PARTICLES     = preload("res://scenes/hit_particles.tscn")
const DEATH_PARTICLES   = preload("res://scenes/death_particles.tscn")
const GRAVITY := -20.0
const KNOCKBACK_DECAY := 12.0
const FLASH_DURATION := 0.1

const COLOR_NORMAL := Color(0.9, 0.45, 0.1, 1)
const COLOR_HIT    := Color(1, 1, 1, 1)
const COLOR_WINDUP := Color(1.0, 0.95, 0.15, 1)

enum State { ROAM, WINDUP, COOLDOWN }

var hp: int
var _player: Node3D = null
var _knockback := Vector3.ZERO
var _flash_timer: float = 0.0
var _state: State = State.ROAM
var _state_timer: float = 0.0
var _material: StandardMaterial3D

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _spawn: Marker3D = $ProjectileSpawn

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	_material = _mesh.get_active_material(0).duplicate()
	_mesh.set_surface_override_material(0, _material)

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	_knockback = _knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	_tick_state(delta)
	_tick_movement(delta)
	_tick_visuals(delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()

func _tick_state(delta: float) -> void:
	if _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	match _state:
		State.ROAM:
			if dist <= shoot_range:
				_state = State.WINDUP
				_state_timer = windup_time
		State.WINDUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_fire()
				_state = State.COOLDOWN
				_state_timer = cooldown_time
		State.COOLDOWN:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = State.ROAM

func _tick_movement(_delta: float) -> void:
	if _player == null:
		velocity.x = _knockback.x
		velocity.z = _knockback.z
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist > 0.1:
		rotation.y = atan2(-to_player.x, -to_player.z)

	var dir := Vector3.ZERO
	if dist > preferred_distance:
		dir = to_player.normalized()
	elif dist < too_close_distance:
		dir = -to_player.normalized()

	velocity.x = dir.x * move_speed + _knockback.x
	velocity.z = dir.z * move_speed + _knockback.z

func _tick_visuals(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_material.albedo_color = COLOR_NORMAL
		return

	if _state == State.WINDUP:
		var t := 1.0 - (_state_timer / windup_time)
		_material.albedo_color = COLOR_NORMAL.lerp(COLOR_WINDUP, t)
	else:
		_material.albedo_color = COLOR_NORMAL

func _fire() -> void:
	if _player == null:
		return
	var proj = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = _spawn.global_position
	var dir := _player.global_position - _spawn.global_position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		proj.initialize(dir.normalized())
	else:
		proj.initialize(-global_transform.basis.z)

func take_damage(amount: int, from_direction: Vector3) -> void:
	hp -= amount
	_material.albedo_color = COLOR_HIT
	_flash_timer = FLASH_DURATION
	Effects.hitstop(0.1)
	Effects.screenshake(0.12)
	var hit := HIT_PARTICLES.instantiate() as CPUParticles3D
	hit.position = global_position + Vector3(0, 0.5, 0)
	get_tree().current_scene.add_child(hit)
	var knock_dir := from_direction
	knock_dir.y = 0.0
	if knock_dir.length_squared() > 0.001:
		_knockback = knock_dir.normalized() * knockback_speed
	if hp <= 0:
		var death := DEATH_PARTICLES.instantiate() as CPUParticles3D
		death.position = global_position + Vector3(0, 0.5, 0)
		get_tree().current_scene.add_child(death)
		queue_free()
