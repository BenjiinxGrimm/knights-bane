extends Area3D

const SPEED: float = 8.0
const DAMAGE: int = 1
const LIFETIME: float = 4.0

var _direction: Vector3 = Vector3.ZERO
var _alive: bool = false

func initialize(dir: Vector3) -> void:
	_direction = dir
	_alive = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	global_position += _direction * SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		return
	if body.is_in_group("player"):
		body.call("take_damage", DAMAGE)
	queue_free()
