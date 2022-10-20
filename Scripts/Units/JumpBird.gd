extends NPCUnit


func before_tick():
	if (abs(player.pos.x - pos.x)) < 3 and (abs(player.pos.y - pos.y)) < 6:
		facing = scene.Constants.Direction.LEFT if player.pos.x < pos.x else scene.Constants.Direction.RIGHT
	elif scene.rng.randf() < 0.5:
		if facing == scene.Constants.Direction.LEFT:
			facing = scene.Constants.Direction.RIGHT
		else:
			facing = scene.Constants.Direction.LEFT
