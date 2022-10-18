extends NPCUnit


func move():
	if (abs(player.pos.x - pos.x)) < 2:
		facing = scene.Constants.Direction.LEFT if player.pos.x < pos.x else scene.Constants.Direction.RIGHT
	.move()
