extends CharacterBody3D

@export var max_hp: int = 3
@export var move_speed: float = 2.5
@export var knockback_speed: float = 8.0
@export var contact_damage: int = 1
@export var damage_interval: float = 1.0

const GRAVITY := -20.0
const KNOCKBACK_DECAY := 12.0
const FLASH_DURATION := 0.1
const ATTACK_RANGE := 1.5
const SEPARATION_RADIUS := 1.8
const SEPARATION_STRENGTH := 1.5

var hp: int
var _player: Node3D = null
var _knockback := Vector3.ZERO
var _flash_timer: float = 0.0
var _damage_timer: float = 0.0
var _approach_angle_offset: float = 0.0
var _material: StandardMaterial3D

@onready var _mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	_approach_angle_offset = randf_range(-0.5, 0.5)
	_material = _mesh.get_active_material(0).duplicate()
	_mesh.set_surface_override_material(0, _material)

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	_knockback = _knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	_damage_timer -= delta

	if _player != null:
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
			if _damage_timer <= 0.0:
				_player.call("take_damage", contact_damage)
				_damage_timer = damage_interval
	else:
		velocity.x = _knockback.x
		velocity.z = _knockback.z

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_material.albedo_color = Color(0.8, 0.15, 0.15, 1)

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

func take_damage(amount: int, from_direction: Vector3) -> void:
	hp -= amount
	_material.albedo_color = Color(1, 1, 1, 1)
	_flash_timer = FLASH_DURATION
	var knock_dir := from_direction
	knock_dir.y = 0.0
	if knock_dir.length_squared() > 0.001:
		_knockback = knock_dir.normalized() * knockback_speed
	if hp <= 0:
		queue_free()
