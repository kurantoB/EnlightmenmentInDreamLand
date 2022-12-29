extends NPCUnit


func before_tick():
	if (abs(player.pos.x - pos.x)) < 3 and (abs(player.pos.y - pos.y)) < 6:
		facing = scene.Constants.Direction.LEFT if player.pos.x < pos.x else scene.Constants.Direction.RIGHT
	elif scene.rng.randf() < 0.5:
		if facing == scene.Constants.Direction.LEFT:
			facing = scene.Constants.Direction.RIGHT
		else:
			facing = scene.Constants.Direction.LEFT

func hit(damage, dir):
	.hit(damage, dir)
	facing = dir

func hit_check():
	# check player slide
	if scene.player.get_current_action() == scene.Constants.UnitCurrentAction.SLIDING and collision_with(scene.player) != -1:
		hit(1, scene.Constants.Direction.RIGHT if player.facing == scene.Constants.Direction.LEFT else scene.Constants.Direction.LEFT)
		scene.player.slide_collision = true
