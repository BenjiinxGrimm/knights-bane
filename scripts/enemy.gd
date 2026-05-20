extends CharacterBody3D

@export var max_hp: int = 3
@export var knockback_speed: float = 8.0

const GRAVITY := -20.0
const KNOCKBACK_DECAY := 12.0
const FLASH_DURATION := 0.1

var hp: int
var _knockback := Vector3.ZERO
var _flash_timer: float = 0.0
var _material: StandardMaterial3D

@onready var _mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	hp = max_hp
	# Duplicate so each enemy instance has its own material to flash independently
	_material = _mesh.get_active_material(0).duplicate()
	_mesh.set_surface_override_material(0, _material)

func _physics_process(delta: float) -> void:
	_knockback = _knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	velocity.x = _knockback.x
	velocity.z = _knockback.z
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_material.albedo_color = Color(0.8, 0.15, 0.15, 1)

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
