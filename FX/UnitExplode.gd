extends AnimatedSprite

func _process(delta: float) -> void:
	if frame == 8:
		queue_free()
