extends NPCUnit


func before_tick():
	if (abs(player.pos.x - pos.x)) < 3 and (abs(player.pos.y - pos.y)) < 6:
		facing = Constants.Direction.LEFT if player.pos.x < pos.x else Constants.Direction.RIGHT
	elif scene.rng.randf() < 0.5:
		if facing == Constants.Direction.LEFT:
			facing = Constants.Direction.RIGHT
		else:
			facing = Constants.Direction.LEFT

func hit(damage, dir):
	.hit(damage, dir)
	facing = dir
