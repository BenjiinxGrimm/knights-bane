extends CharacterBody3D

@export var max_hp: int = 3
@export var move_speed: float = 2.5
@export var knockback_speed: float = 8.0
@export var contact_damage: int = 1
@export var anim_player: AnimationPlayer
@export var mesh: MeshInstance3D

const GRAVITY := -20.0
const KNOCKBACK_DECAY := 12.0
const FLASH_DURATION := 0.1
const ATTACK_RANGE := 1.5
const WINDUP_TIME := 0.5
const ATTACK_COOLDOWN := 1.2
const SEPARATION_RADIUS := 1.8
const SEPARATION_STRENGTH := 1.5
const TURN_SPEED := 8.0
const GRAB_STUN_DURATION := 0.3
const DEATH_LINGER := 5.0
const ATTACK_ANIM_DURATION := 2.53
const GRAB_ANIM_DURATION := 4.30

const HIT_PARTICLES   = preload("res://scenes/hit_particles.tscn")
const DEATH_PARTICLES = preload("res://scenes/death_particles.tscn")

const COLOR_NORMAL := Color(0.8, 0.15, 0.15, 1)
const COLOR_WINDUP := Color(1.0, 0.65, 0.0, 1)
const COLOR_HIT    := Color(1, 1, 1, 1)

enum AttackPhase { IDLE, WINDUP, COOLDOWN }
enum AttackType { REGULAR, GRAB }

var hp: int
var _player: Node3D = null
var _knockback := Vector3.ZERO
var _flash_timer: float = 0.0
var _attack_phase: AttackPhase = AttackPhase.IDLE
var _attack_timer: float = 0.0
var _attack_type: AttackType = AttackType.REGULAR
var _approach_angle_offset: float = 0.0
var _material: StandardMaterial3D
var _dying: bool = false
var _death_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	_approach_angle_offset = randf_range(-0.5, 0.5)
	if mesh != null:
		_material = mesh.get_active_material(0).duplicate()
		mesh.set_surface_override_material(0, _material)

func _physics_process(delta: float) -> void:
	if _dying:
		_death_timer -= delta
		if _death_timer <= 0.0:
			queue_free()
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	_knockback = _knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	_tick_attack(delta)
	_tick_movement(delta)
	_tick_facing(delta)
	_tick_visuals(delta)
	_update_animation()

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()

func _tick_attack(delta: float) -> void:
	if _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	match _attack_phase:
		AttackPhase.IDLE:
			if dist <= ATTACK_RANGE:
				_attack_type = AttackType.GRAB if randf() < 0.35 else AttackType.REGULAR
				_attack_phase = AttackPhase.WINDUP
				_attack_timer = WINDUP_TIME
		AttackPhase.WINDUP:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				if dist <= ATTACK_RANGE + 0.5:
					_player.call("take_damage", contact_damage)
					if _attack_type == AttackType.GRAB:
						_player.call("grab", GRAB_STUN_DURATION)
				_attack_phase = AttackPhase.COOLDOWN
				var anim_duration := GRAB_ANIM_DURATION if _attack_type == AttackType.GRAB else ATTACK_ANIM_DURATION
				_attack_timer = max(anim_duration - WINDUP_TIME, 0.2)
		AttackPhase.COOLDOWN:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_phase = AttackPhase.IDLE

func _tick_movement(delta: float) -> void:
	if _player == null:
		velocity.x = _knockback.x
		velocity.z = _knockback.z
		return

	if _attack_phase == AttackPhase.WINDUP:
		velocity.x = _knockback.x
		velocity.z = _knockback.z
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist > ATTACK_RANGE:
		var dir := (to_player / dist).rotated(Vector3.UP, _approach_angle_offset)
		dir += _separation_from_others()
		if dir.length_squared() > 0.001:
			dir = dir.normalized()
		velocity.x = dir.x * move_speed + _knockback.x
		velocity.z = dir.z * move_speed + _knockback.z
	else:
		velocity.x = _knockback.x
		velocity.z = _knockback.z

func _tick_facing(delta: float) -> void:
	if _player == null:
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.001:
		return
	var target_angle := atan2(to_player.x, to_player.z)
	rotation.y = lerp_angle(rotation.y, target_angle, TURN_SPEED * delta)

func _tick_visuals(delta: float) -> void:
	if _material == null:
		return
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_material.albedo_color = COLOR_NORMAL
		return

	if _attack_phase == AttackPhase.WINDUP:
		var t := 1.0 - (_attack_timer / WINDUP_TIME)
		_material.albedo_color = COLOR_NORMAL.lerp(COLOR_WINDUP, t)
	else:
		_material.albedo_color = COLOR_NORMAL

func _update_animation() -> void:
	if anim_player == null:
		return
	var anim: String
	match _attack_phase:
		AttackPhase.WINDUP:
			anim = "Grab And Slam" if _attack_type == AttackType.GRAB else "attack"
		AttackPhase.COOLDOWN:
			anim = "Grab And Slam" if _attack_type == AttackType.GRAB else "attack"
		AttackPhase.IDLE:
			if _player != null:
				var to_player := _player.global_position - global_position
				to_player.y = 0.0
				if to_player.length() > ATTACK_RANGE:
					anim = "walk"
				else:
					anim = "idle"
			else:
				anim = "idle"
	if anim_player.current_animation != anim:
		anim_player.play(anim)

func _separation_from_others() -> Vector3:
	var sep := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemy"):
		var other_node := other as Node3D
		if other_node == null or other_node == self:
			continue
		var away := global_position - other_node.global_position
		away.y = 0.0
		var d := away.length()
		if d < SEPARATION_RADIUS and d > 0.001:
			sep += away.normalized() * (1.0 - d / SEPARATION_RADIUS)
	return sep * SEPARATION_STRENGTH

func take_damage(amount: int, from_direction: Vector3, knockback_mult: float = 1.0) -> void:
	if _dying:
		return
	hp -= amount
	if _material != null:
		_material.albedo_color = COLOR_HIT
	_flash_timer = FLASH_DURATION
	Effects.hitstop(0.1)
	Effects.screenshake(0.12)
	Audio.play_hit_enemy()
	var hit := HIT_PARTICLES.instantiate() as CPUParticles3D
	hit.position = global_position + Vector3(0, 0.5, 0)
	get_tree().current_scene.add_child(hit)
	var knock_dir := from_direction
	knock_dir.y = 0.0
	if knock_dir.length_squared() > 0.001:
		_knockback = knock_dir.normalized() * knockback_speed * knockback_mult
	if hp <= 0:
		_dying = true
		_death_timer = DEATH_LINGER
		if anim_player != null:
			anim_player.play("death")
		var death := DEATH_PARTICLES.instantiate() as CPUParticles3D
		death.position = global_position + Vector3(0, 0.5, 0)
		get_tree().current_scene.add_child(death)
