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

func init_player(player : Unit):
	player.pos = Vector2(player.position.x / Constants.GRID_SIZE, -1 * player.position.y / Constants.GRID_SIZE)

func interact(unit : Unit, delta):
	if unit.unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED]:
		if unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if unit.v_speed < 0:
				# recalibrate move vector and set y position to be on ground
				ground_movement_interaction(unit, delta)
		else:
			unit.v_speed = max(unit.v_speed - Constants.GRAVITY * delta, Constants.MAX_FALL_SPEED)
	
	if not (unit.h_speed == 0 and unit.v_speed == 0):
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

	if unit.debug_elapsed > unit.next_debug_time:
		print("interact h_speed: " + str(unit.h_speed) + ", v_speed: " + str(unit.v_speed))

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
	var angle_helper = []
	for collider in bottom_left_colliders:
		if unit_is_colliding_w_env(unit, collider, [Constants.DIRECTION.DOWN], delta)[0]:
			if unit.facing == Constants.PlayerInput.RIGHT:
				angle_helper = collider
			else:
				angle_helper = [collider[1], collider[0]]
			has_ground_collision = true
			break	
	if not has_ground_collision:
		unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = false
		if unit.facing == Constants.PlayerInput.RIGHT:
			angle_helper = [Vector2(0, 0), Vector2(1, 0)]
		else:
			angle_helper = [Vector2(1, 0), Vector2(0, 0)]
		print("But there's no ground collision")
	GameUtils.reangle_move(unit, angle_helper)

func check_collision(unit : Unit, collider, collision_directions, delta):
	var env_collision = unit_is_colliding_w_env(unit, collider, collision_directions, delta)
	if env_collision[0]:
		var collision_point = env_collision[2]
		if env_collision[1] == Constants.DIRECTION.DOWN:
			check_ground_collision(unit, collider, collision_point)
		elif env_collision[1] == Constants.DIRECTION.LEFT or env_collision[1] == Constants.DIRECTION.RIGHT:
			unit.h_speed = 0
			for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
				if unit_env_collider[1].has(env_collision[1]):
					var collider_set_pos_x = collision_point.x
					if env_collision[1] == Constants.DIRECTION.LEFT:
						collider_set_pos_x = collider_set_pos_x + Constants.QUANTUM_DIST
					else:
						collider_set_pos_x = collider_set_pos_x - Constants.QUANTUM_DIST
					var x_dist_to_translate = collider_set_pos_x - unit_env_collider[0].x
					unit.pos.x = unit.pos.x + x_dist_to_translate
		elif env_collision[1] == Constants.DIRECTION.UP:
			unit.v_speed = 0
			for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
				if unit_env_collider[1].has(Constants.DIRECTION.UP):
					var collider_set_pos_y = collision_point.y - Constants.QUANTUM_DIST
					var y_dist_to_translate = collider_set_pos_y - unit_env_collider[0].y
					unit.pos.y = unit.pos.y + y_dist_to_translate
	return env_collision[0]

# bonce?
func check_ground_collision(unit : Unit, collider, collision_point : Vector2):
	if (unit.unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED]
		and not unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]
		and (collider[0].y == collider[1].y or (collider[0].x != collider[1].x and collider[0].y != collider[1].y))):
			if unit.v_speed <= Constants.MIN_BOUNCE_SPEED:
				unit.v_speed = -1 * unit.v_speed * .5
			else:
				unit.v_speed = 0
				unit.h_speed = 0
				for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
					if unit_env_collider[1].has(Constants.DIRECTION.DOWN):
						var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
						var y_dist_to_translate = collider_set_pos_y - unit_env_collider[0].y
						unit.pos.y = unit.pos.y + y_dist_to_translate
						var x_dist_to_translate = collision_point.x - unit_env_collider[0].x
						unit.pos.x = unit.pos.x + x_dist_to_translate
						break
				unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = true

# returns true/false, collision direction, and collision point
func unit_is_colliding_w_env(unit : Unit, collider, directions, delta):
	for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
		for direction_to_check in directions:
			if unit_env_collider[1].has(direction_to_check):
				var unit_env_collider_vector = unit_env_collider[0]
				if unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
					unit_env_collider_vector.y = unit_env_collider_vector.y * Constants.CROUCH_FACTOR
				var collision_check : Vector2 = unit.pos + unit_env_collider_vector
				var intersects_results = GameUtils.path_intersects_border(
					collision_check,
					collision_check + Vector2(unit.h_speed * delta, unit.v_speed * delta),
					collider[0],
					collider[1])
				if intersects_results[0]:
					# print("Found collision on " + Constants.DIRECTION.keys()[direction_to_check] + " collision_check_from: " + str(collision_check) + ", collision_check_to: " + str(collision_check + Vector2(unit.h_speed * delta, unit.v_speed * delta)) + ", collider[0]: " + str(collider[0]) + ", collider[1]: " + str(collider[1]))
					return [true, direction_to_check, intersects_results[1]]
	return [false, -1]