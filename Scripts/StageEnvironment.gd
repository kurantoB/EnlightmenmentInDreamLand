extends Object

const GameUtils = preload("res://Scripts/GameUtils.gd")
const Constants = preload("res://Scripts/Constants.gd")
const GameScene = preload("res://Scripts/GameScene.gd")
const Unit = preload("res://Scripts/Unit.gd")

var scene : GameScene

var top_right_colliders = []
var bottom_right_colliders = []
var bottom_left_colliders = []
var top_left_colliders = []

func _init(the_scene : GameScene):
	scene = the_scene
	var stage = scene.get_node("Stage")
	init_stage_grid(stage.get_children())
	for stage_elem in stage.get_children():
		stage_elem.position.x = stage_elem.position.x * Constants.SCALE_FACTOR
		stage_elem.position.y = stage_elem.position.y * Constants.SCALE_FACTOR
		stage_elem.scale.x = Constants.SCALE_FACTOR
		stage_elem.scale.y = Constants.SCALE_FACTOR
	var player = scene.get_node("Player")
	init_player(player)
	player.position.x = player.position.x * Constants.SCALE_FACTOR
	player.position.y = player.position.y * Constants.SCALE_FACTOR
	player.scale.x = Constants.SCALE_FACTOR
	player.scale.y = Constants.SCALE_FACTOR
	
	if scene.has_node("Background"):
		var background = scene.get_node("Background")
		for stage_elem in background.get_children():
			stage_elem.position.x = stage_elem.position.x * Constants.SCALE_FACTOR
			stage_elem.position.y = stage_elem.position.y * Constants.SCALE_FACTOR
			stage_elem.scale.x = Constants.SCALE_FACTOR
			stage_elem.scale.y = Constants.SCALE_FACTOR

func init_player(player : Unit):
	player.pos = Vector2(player.position.x / Constants.GRID_SIZE, -1 * player.position.y / Constants.GRID_SIZE)

func interact(unit : Unit, delta):
	# gravity-affected
	if unit.unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED]:
		# gravity-affected, grounded
		if unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			# gravity-affected, grounded, -v
			if unit.v_speed < 0:
				scene.conditional_log("gravity-affected, grounded, -v")
				# recalibrate move vector and set y position to be on ground
				ground_movement_interaction(unit, delta)
			else:
				scene.conditional_log("gravity-affected, grounded, v_speed-zero: zero-out speed")
				unit.h_speed = 0
				unit.v_speed = 0
		else:
			scene.conditional_log("not-on-ground")
			var gravity_factor = Constants.GRAVITY
			var max_fall_speed = Constants.MAX_FALL_SPEED
			if unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
				gravity_factor = Constants.GRAVITY_LITE
				max_fall_speed = Constants.MAX_FALL_LITE
			scene.conditional_log("change-v-speed: " + str(unit.v_speed) + " -> " + str(max(unit.v_speed - (gravity_factor * delta), max_fall_speed)))
			unit.v_speed = max(unit.v_speed - (gravity_factor * delta), max_fall_speed)

	if not (unit.h_speed == 0 and unit.v_speed == 0):
		scene.conditional_log("not-still")
		# regular collision
		if unit.h_speed >= 0 and unit.v_speed > 0:
			for collider in top_right_colliders:
				if check_collision(unit, collider, [Constants.DIRECTION.UP, Constants.DIRECTION.RIGHT], delta):
					break
		elif unit.h_speed > 0 and unit.v_speed <= 0:
			for collider in bottom_right_colliders:
				if check_collision(unit, collider, [Constants.DIRECTION.RIGHT, Constants.DIRECTION.DOWN], delta):
					break
		elif unit.h_speed <= 0 and unit.v_speed < 0:
			for collider in bottom_left_colliders:
				if check_collision(unit, collider, [Constants.DIRECTION.DOWN, Constants.DIRECTION.LEFT], delta):
					break
		elif unit.h_speed < 0 and unit.v_speed >= 0:
			for collider in top_left_colliders:
				if check_collision(unit, collider, [Constants.DIRECTION.LEFT, Constants.DIRECTION.UP], delta):
					break

func init_stage_grid(map_elems):
	for map_elem in map_elems:
		var stage_x = floor(map_elem.position.x / Constants.GRID_SIZE)
		var stage_y = floor(-1 * map_elem.position.y / Constants.GRID_SIZE)
		match map_elem.map_elem_type:
			Constants.MAP_ELEM_TYPES.SQUARE:
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.UP, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, 1)
			Constants.MAP_ELEM_TYPES.SLOPE_LEFT:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SLOPE_RIGHT:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_LEFT_1:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_LEFT_2:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_RIGHT_1:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_RIGHT_2:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.LEDGE:
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.UP, 1)


func insert_grid_collider(stage_x, stage_y, direction : int, fractional_height : float):
	var check_colliders = []
	var insert_colliders = []
	var point_a : Vector2
	var point_b : Vector2
	match direction:
		Constants.DIRECTION.UP:
			check_colliders = [top_right_colliders, top_left_colliders]
			insert_colliders = [bottom_right_colliders, bottom_left_colliders]
			point_a = Vector2(stage_x, stage_y + 1)
			point_b = Vector2(stage_x + 1, stage_y + 1)
		Constants.DIRECTION.DOWN:
			check_colliders = [bottom_right_colliders, bottom_left_colliders]
			insert_colliders = [top_right_colliders, top_left_colliders]
			point_a = Vector2(stage_x, stage_y)
			point_b = Vector2(stage_x + 1, stage_y)
		Constants.DIRECTION.LEFT:
			check_colliders = [bottom_left_colliders, top_left_colliders]
			insert_colliders = [top_right_colliders, bottom_right_colliders]
			point_a = Vector2(stage_x, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x, stage_y)
		Constants.DIRECTION.RIGHT:
			check_colliders = [top_right_colliders, bottom_right_colliders]
			insert_colliders = [bottom_left_colliders, top_left_colliders]
			point_a = Vector2(stage_x + 1, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x + 1, stage_y)
	try_insert_collider(check_colliders, insert_colliders, point_a, point_b)

func try_insert_collider(check_colliders, insert_colliders, point_a : Vector2, point_b : Vector2):
	var found_existing : bool = false
	for i in range(len(check_colliders)):
		for j in range(len(check_colliders[i])):
			if check_colliders[i][j][0] == point_a and check_colliders[i][j][1] == point_b:
				found_existing = true
				check_colliders[i].remove(j)
				break
	if not found_existing:
		for i in range(len(insert_colliders)):
			insert_colliders[i].append([point_a, point_b])

func ground_movement_interaction(unit : Unit, delta):
	var has_ground_collision = false
	var collider_group = []
	var angle_helper
	for collider in bottom_left_colliders:
		var env_collision = unit_is_colliding_w_env(unit, collider, [Constants.DIRECTION.DOWN], delta, true)
		if env_collision[0]:
			# collided with ground
			has_ground_collision = true
			scene.conditional_log("ground-collided: " + str(collider))
			if unit.h_speed > 0:
				scene.conditional_log("positive h_speed")
				angle_helper = collider
			else:
				scene.conditional_log("negative h_speed")
				angle_helper = [collider[1], collider[0]]
			scene.conditional_log("zero-out h_speed")
			unit.h_speed = 0
			var collision_point = env_collision[2]
			var unit_env_collider = env_collision[3]
			var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			scene.conditional_log("change-pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
			unit.pos.y = unit.pos.y + y_dist_to_translate
			var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
			scene.conditional_log("change-pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
			unit.pos.x = unit.pos.x + x_dist_to_translate
			break
	if not has_ground_collision:
		scene.conditional_log("not-ground-collided")
		unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = false
		if unit.h_speed > 0:
			scene.conditional_log("positive h_speed")
			angle_helper = [Vector2(0, 0), Vector2(1, 0)]
		else:
			scene.conditional_log("negative h_speed")
			angle_helper = [Vector2(1, 0), Vector2(0, 0)]
		scene.conditional_log("zero-out h_speed")
		unit.h_speed = 0
	scene.conditional_log("reangling: " + str(Vector2(unit.h_speed, unit.v_speed)) + " ->")
	GameUtils.reangle_move(unit, angle_helper)
	scene.conditional_log("reangling:     " + str(Vector2(unit.h_speed, unit.v_speed)))
	

func check_collision(unit : Unit, collider, collision_directions, delta):
	var env_collision = unit_is_colliding_w_env(unit, collider, collision_directions, delta)
	if env_collision[0]:
		var collision_dir = env_collision[1]
		var collision_point = env_collision[2]
		var unit_env_collider = env_collision[3]
		scene.conditional_log("collided: " + str(collider) + " direction: " + Constants.DIRECTION.keys()[env_collision[1]] + ", at " + str(collision_point) + " w/ env-collider: " + str(unit_env_collider[0]))
		check_ground_collision(unit, collider, collision_point, unit_env_collider)
		if collision_dir == Constants.DIRECTION.UP:
			unit.v_speed = 0
			var collider_set_pos_y = collision_point.y - Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			unit.pos.y = unit.pos.y + y_dist_to_translate
		elif collision_dir == Constants.DIRECTION.LEFT or collision_dir == Constants.DIRECTION.RIGHT:
			unit.h_speed = 0
			var collider_set_pos_x = collision_point.x
			if collision_dir == Constants.DIRECTION.LEFT:
				collider_set_pos_x = collider_set_pos_x + Constants.QUANTUM_DIST
			else:
				collider_set_pos_x = collider_set_pos_x - Constants.QUANTUM_DIST
			var x_dist_to_translate = collider_set_pos_x - (unit.pos.x + unit_env_collider[0].x)
			unit.pos.x = unit.pos.x + x_dist_to_translate
	return env_collision[0]

# returns if collision is with ground
func check_ground_collision(unit : Unit, collider, collision_point : Vector2, unit_env_collider):
	if not unit_env_collider[1].has(Constants.DIRECTION.DOWN):
		return false
	if (unit.unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED]
		and not unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]
		and (collider[0].y == collider[1].y or (collider[0].x != collider[1].x and collider[0].y != collider[1].y))):
		scene.conditional_log("airborne ground-collided: " + str(collider))
		scene.conditional_log("redirect speed")
		unit.v_speed = 0
		unit.h_speed = 0
		var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
		var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
		scene.conditional_log("change pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
		unit.pos.y = unit.pos.y + y_dist_to_translate
		var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
		scene.conditional_log("change pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
		unit.pos.x = unit.pos.x + x_dist_to_translate
		scene.conditional_log("set grounded")
		unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = true
		if unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] = Constants.UnitCurrentAction.IDLE
		return true
	return false
	

# returns true/false, collision direction, collision point, and unit env collider
func unit_is_colliding_w_env(unit : Unit, collider, directions, delta, is_ground_check = false):
	for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
		for direction_to_check in directions:
			if not unit_env_collider[1].has(direction_to_check):
				continue
			var unit_env_collider_vector = unit_env_collider[0]
			if unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING or unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING:
				unit_env_collider_vector.y = unit_env_collider_vector.y * Constants.CROUCH_FACTOR
			var collision_check : Vector2 = unit.pos + unit_env_collider_vector
			var altered_collision_check: Vector2 = collision_check
			if is_ground_check:
				altered_collision_check.y = altered_collision_check.y + .3
			var intersects_results = GameUtils.path_intersects_border(
				altered_collision_check,
				collision_check + Vector2(unit.h_speed * delta, unit.v_speed * delta),
				collider[0],
				collider[1])
			if intersects_results[0]:
				var true_dir_to_check : int = direction_to_check
				if collider[0].y == collider[1].y:
					if unit_env_collider[1].has(Constants.DIRECTION.UP) and directions.has(Constants.DIRECTION.UP):
						true_dir_to_check = Constants.DIRECTION.UP
					elif unit_env_collider[1].has(Constants.DIRECTION.DOWN) and directions.has(Constants.DIRECTION.DOWN):
						true_dir_to_check = Constants.DIRECTION.DOWN
					else:
						return [false, -1, Vector2(), {}]
				if collider[0].x == collider[1].x:
					if unit_env_collider[1].has(Constants.DIRECTION.LEFT) and directions.has(Constants.DIRECTION.LEFT):
						true_dir_to_check = Constants.DIRECTION.LEFT
					elif unit_env_collider[1].has(Constants.DIRECTION.RIGHT) and directions.has(Constants.DIRECTION.RIGHT):
						true_dir_to_check = Constants.DIRECTION.RIGHT
					else:
						return [false, -1, Vector2(), {}]
				return [true, true_dir_to_check, intersects_results[1], unit_env_collider]
	return [false, -1, Vector2(), {}]
