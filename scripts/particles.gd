extends CPUParticles3D

func _ready() -> void:
	emitting = true
	get_tree().create_timer(lifetime + 0.1).timeout.connect(queue_free)
