extends Object

const GameUtils = preload("res://Scripts/GameUtils.gd")
const GameScene = preload("res://Scripts/GameScene.gd")
const Unit = preload("res://Scripts/Unit.gd")

var scene : GameScene

var top_right_colliders = []
var bottom_right_colliders = []
var bottom_left_colliders = []
var top_left_colliders = []
var stage_hazards = [] # [[bounds, bound_direction], ...]

func _init(the_scene : GameScene):
	scene = the_scene
	var stage : TileMap = scene.get_node("Stage")
	init_stage_grid(stage)
	stage.scale.x = scene.Constants.SCALE_FACTOR
	stage.scale.y = scene.Constants.SCALE_FACTOR
	var player = scene.get_node("Player")
	init_player(player)
	player.position.x = player.position.x * scene.Constants.SCALE_FACTOR
	player.position.y = player.position.y * scene.Constants.SCALE_FACTOR

func init_player(player : Unit):
	player.pos = Vector2(player.position.x / scene.Constants.GRID_SIZE, -1 * player.position.y / scene.Constants.GRID_SIZE)

func interact(unit : Unit, delta):
	# do hazards
	if not unit.get_condition(scene.Constants.UnitCondition.IS_INVINCIBLE, false):
		var unit_pos_y_upper_bound_check = unit.hit_box[scene.Constants.HIT_BOX_BOUND.UPPER_BOUND]
		if unit_is_shortened(unit):
			unit_pos_y_upper_bound_check *= scene.Constants.CROUCH_FACTOR
		for stage_hazard in stage_hazards:
			if not ((unit.pos.y + unit.hit_box[scene.Constants.HIT_BOX_BOUND.LOWER_BOUND] > stage_hazard[0][scene.Constants.HIT_BOX_BOUND.UPPER_BOUND])
			or (unit.pos.y + unit_pos_y_upper_bound_check < stage_hazard[0][scene.Constants.HIT_BOX_BOUND.LOWER_BOUND])
			or (unit.pos.x + unit.hit_box[scene.Constants.HIT_BOX_BOUND.LEFT_BOUND] > stage_hazard[0][scene.Constants.HIT_BOX_BOUND.RIGHT_BOUND])
			or (unit.pos.x + unit.hit_box[scene.Constants.HIT_BOX_BOUND.RIGHT_BOUND] < stage_hazard[0][scene.Constants.HIT_BOX_BOUND.LEFT_BOUND])):
				var dir: int
				if stage_hazard[1] != -1:
					dir = stage_hazard[1]
				elif (stage_hazard[0][scene.Constants.HIT_BOX_BOUND.LEFT_BOUND] + stage_hazard[0][scene.Constants.HIT_BOX_BOUND.RIGHT_BOUND]) / 2 < unit.pos.x:
					dir = scene.Constants.Direction.LEFT
				else:
					dir = scene.Constants.Direction.RIGHT
				unit.hit(1, dir)
				break

	# do collisions
	
	# gravity-affected
	if not unit.no_gravity:
		# gravity-affected, grounded
		if unit.unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]:
			# gravity-affected, grounded, -v
			scene.conditional_log("interact gravity-affected, grounded - interact_grounded")
			interact_grounded(unit, delta)
		else:
			var gravity_factor = scene.gravity
			var max_fall_speed = scene.max_fall_speed
			if unit.get_current_action() == scene.Constants.UnitCurrentAction.FLYING:
				scene.conditional_log("interact gravity-affected, not-grounded, flying - use GRAVITY_LITE, MAX_FALL_LITE")
				gravity_factor = scene.gravity_lite
				max_fall_speed = scene.max_fall_speed_lite
			elif unit.get_current_action() == scene.Constants.UnitCurrentAction.FLYING_CEILING:
				gravity_factor = scene.gravity_lite
				max_fall_speed = 0
			scene.conditional_log("interact gravity-affected, not-grounded, change-v-speed: " + str(unit.v_speed) + " -> " + str(max(unit.v_speed - (gravity_factor * delta), max_fall_speed)))
			unit.v_speed = max(unit.v_speed - (gravity_factor * delta), max_fall_speed)

	if not (unit.h_speed == 0 and unit.v_speed == 0):
		# regular collision
		if unit.h_speed >= 0 and unit.v_speed > 0:
			scene.conditional_log("interact not-still check UP, RIGHT")
			for collider in top_right_colliders:
				check_collision(unit, collider, scene.Constants.Direction.UP, delta)
			for collider in top_right_colliders:
				check_collision(unit, collider, scene.Constants.Direction.RIGHT, delta)
			for collider in top_right_colliders:
				check_collision(unit, collider, scene.Constants.Direction.UP, delta)
		elif unit.h_speed > 0 and unit.v_speed <= 0:
			scene.conditional_log("interact not-still check RIGHT, DOWN, RIGHT")
			# We have to make sure every horizontal-direction check is preceded by a down check, and vice versa...
			for collider in bottom_right_colliders:
				check_collision(unit, collider, scene.Constants.Direction.RIGHT, delta)
			for collider in bottom_right_colliders:
				check_collision(unit, collider, scene.Constants.Direction.DOWN, delta)
			for collider in bottom_right_colliders:
				check_collision(unit, collider, scene.Constants.Direction.RIGHT, delta)
		elif unit.h_speed <= 0 and unit.v_speed < 0:
			scene.conditional_log("interact not-still check LEFT, DOWN, LEFT")
			# We have to make sure every horizontal-direction check is preceded by a down check, and vice versa...
			for collider in bottom_left_colliders:
				check_collision(unit, collider, scene.Constants.Direction.LEFT, delta)
			for collider in bottom_left_colliders:
				check_collision(unit, collider, scene.Constants.Direction.DOWN, delta)
			for collider in bottom_left_colliders:
				check_collision(unit, collider, scene.Constants.Direction.LEFT, delta)
		elif unit.h_speed < 0 and unit.v_speed >= 0:
			scene.conditional_log("interact not-still check LEFT, UP")
			for collider in top_left_colliders:
				check_collision(unit, collider, scene.Constants.Direction.UP, delta)
			for collider in top_left_colliders:
				check_collision(unit, collider, scene.Constants.Direction.LEFT, delta)
			for collider in top_left_colliders:
				check_collision(unit, collider, scene.Constants.Direction.UP, delta)

func interact_grounded(unit : Unit, delta):
	# gravity-affected, grounded, v-speed-negative
	if unit.v_speed < 0:
		scene.conditional_log("interact_grounded neg v-speed - ground_movement_interaction")
		ground_movement_interaction(unit, delta)
	# gravity-affected, grounded, v-speed-zero
	else:
		scene.conditional_log("interact_grounded v-speed-zero - zero-out speed, ground_placement")
		unit.h_speed = 0
		unit.v_speed = 0
		ground_placement(unit)

func init_stage_grid(tilemap : TileMap):
	for map_elem in tilemap.get_used_cells():
		var stage_x = floor(tilemap.map_to_world(map_elem).x / scene.Constants.GRID_SIZE)
		var stage_y = floor(-1 * tilemap.map_to_world(map_elem).y / scene.Constants.GRID_SIZE) - 1
		var map_elem_type : int
		var cellv = tilemap.get_cellv(map_elem)
		var found_map_elem_type : bool = false
		for test_map_elem_type in [
			scene.Constants.MapElemType.SQUARE,
			scene.Constants.MapElemType.SLOPE_LEFT,
			scene.Constants.MapElemType.SLOPE_RIGHT,
			scene.Constants.MapElemType.SMALL_SLOPE_LEFT_1,
			scene.Constants.MapElemType.SMALL_SLOPE_LEFT_2,
			scene.Constants.MapElemType.SMALL_SLOPE_RIGHT_1,
			scene.Constants.MapElemType.SMALL_SLOPE_RIGHT_2,
			scene.Constants.MapElemType.LEDGE,
			scene.Constants.MapElemType.HAZARD]:
			for test_cell_v in scene.Constants.TILE_SET_MAP_ELEMS[scene.tile_set_name][test_map_elem_type]:
				if test_cell_v == cellv:
					map_elem_type = test_map_elem_type
					found_map_elem_type = true
					break
			if found_map_elem_type:
				break
		match map_elem_type:
			scene.Constants.MapElemType.SQUARE:
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.UP, 1)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.DOWN, 1)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.RIGHT, 1)
			scene.Constants.MapElemType.SLOPE_LEFT:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.DOWN, 1)
			scene.Constants.MapElemType.SLOPE_RIGHT:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.DOWN, 1)
			scene.Constants.MapElemType.SMALL_SLOPE_LEFT_1:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.DOWN, 1)
			scene.Constants.MapElemType.SMALL_SLOPE_LEFT_2:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.DOWN, 1)
			scene.Constants.MapElemType.SMALL_SLOPE_RIGHT_1:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.DOWN, 1)
			scene.Constants.MapElemType.SMALL_SLOPE_RIGHT_2:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.DOWN, 1)
			scene.Constants.MapElemType.LEDGE:
				insert_grid_collider(stage_x, stage_y, scene.Constants.Direction.UP, 1)
			scene.Constants.MapElemType.HAZARD:
				insert_stage_hazard(stage_x, stage_y, cellv)


func insert_grid_collider(stage_x, stage_y, direction : int, fractional_height : float):
	var check_colliders = []
	var insert_colliders = []
	var point_a : Vector2
	var point_b : Vector2
	match direction:
		scene.Constants.Direction.UP:
			check_colliders = [top_right_colliders, top_left_colliders]
			insert_colliders = [bottom_right_colliders, bottom_left_colliders]
			point_a = Vector2(stage_x, stage_y + 1)
			point_b = Vector2(stage_x + 1, stage_y + 1)
		scene.Constants.Direction.DOWN:
			check_colliders = [bottom_right_colliders, bottom_left_colliders]
			insert_colliders = [top_right_colliders, top_left_colliders]
			point_a = Vector2(stage_x, stage_y)
			point_b = Vector2(stage_x + 1, stage_y)
		scene.Constants.Direction.LEFT:
			check_colliders = [bottom_left_colliders, top_left_colliders]
			insert_colliders = [top_right_colliders, bottom_right_colliders]
			point_a = Vector2(stage_x, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x, stage_y)
		scene.Constants.Direction.RIGHT:
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

func insert_stage_hazard(stage_x, stage_y, cellv):
	stage_hazards.append([{
		scene.Constants.HIT_BOX_BOUND.UPPER_BOUND: stage_y + 1,
		scene.Constants.HIT_BOX_BOUND.LOWER_BOUND: stage_y,
		scene.Constants.HIT_BOX_BOUND.LEFT_BOUND: stage_x,
		scene.Constants.HIT_BOX_BOUND.RIGHT_BOUND: stage_x + 1}, scene.Constants.TILE_SET_HAZARD_REF_X[scene.tile_set_name][cellv]])

func ground_movement_interaction(unit : Unit, delta):
	var has_ground_collision = false
	var collider_group = []
	var angle_helper_collider
	for collider in bottom_left_colliders:
		# true/false, collision direction, collision point, and unit env collider
		var env_collision = unit_is_colliding_w_env(unit, collider, scene.Constants.Direction.DOWN, delta, true)
		if env_collision[0]:
			# collided with ground
			scene.conditional_log("ground_movement_interaction ground-collided: " + str(collider) + " at " + str(env_collision[2]))
			has_ground_collision = true
			var collision_point = env_collision[2]
			var unit_env_collider = env_collision[3]
			var collider_set_pos_y = collision_point.y + scene.Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			scene.conditional_log("ground_movement_interaction change-pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
			unit.pos.y = unit.pos.y + y_dist_to_translate
			var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
			scene.conditional_log("ground_movement_interaction change-pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
			unit.pos.x = unit.pos.x + x_dist_to_translate
			angle_helper_collider = collider
			unit.last_contacted_collider = collider
			break
	if not has_ground_collision:
		scene.conditional_log("ground_movement_interaction not-ground-collided - is-on-ground-false")
		unit.set_unit_condition(scene.Constants.UnitCondition.IS_ON_GROUND, false)
	var angle_helper
	if unit.h_speed > 0:
		if has_ground_collision:
			angle_helper = angle_helper_collider
		else:
			angle_helper = [unit.last_contacted_collider[0], unit.last_contacted_collider[1]]
	else:
		if has_ground_collision:
			angle_helper = [angle_helper_collider[1], angle_helper_collider[0]]
		else:
			angle_helper = [unit.last_contacted_collider[1], unit.last_contacted_collider[0]]
	scene.conditional_log("ground_movement_interaction ground-collided angle_helper: " + str(angle_helper) + ", zero-out h-speed")
	unit.h_speed = 0
	scene.conditional_log("ground_movement_interaction reangling: " + str(Vector2(unit.h_speed, unit.v_speed)) + " ->")
	GameUtils.reangle_move(unit, angle_helper)
	scene.conditional_log("ground_movement_interaction reangling:     " + str(Vector2(unit.h_speed, unit.v_speed)))

func ground_placement(unit : Unit):
	for unit_env_collider in scene.Constants.ENV_COLLIDERS[unit.unit_type]:
		if unit_env_collider[0] != Vector2(0, 0):
			continue
		for collider in bottom_left_colliders:
			if collider[0].x == collider[1].x:
				continue
			var collision_check : Vector2 = unit.pos + unit_env_collider[0]
			var altered_collision_check: Vector2 = collision_check
			altered_collision_check.y = altered_collision_check.y + .9
			var intersects_results = GameUtils.path_intersects_border(
				altered_collision_check,
				collision_check + Vector2(0, -.3),
				collider[0],
				collider[1])
			if intersects_results[0]:
				scene.conditional_log("ground_still_placement for collider " + str(collider))
				var collision_point = intersects_results[1]
				var collider_set_pos_y = collision_point.y + scene.Constants.QUANTUM_DIST
				var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
				scene.conditional_log("ground_still_placement change pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
				unit.pos.y = unit.pos.y + y_dist_to_translate
				var collider_set_pos_x = collision_point.x
				var x_dist_to_translate = collider_set_pos_x - (unit.pos.x + unit_env_collider[0].x)
				scene.conditional_log("ground_still_placement change pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
				unit.pos.x = unit.pos.x + x_dist_to_translate
				unit.last_contacted_collider = collider
				return
	
func check_collision(unit : Unit, collider, collision_direction, delta):
	# true/false, collision direction, collision point, and unit env collider
	var env_collision = unit_is_colliding_w_env(unit, collider, collision_direction, delta)
	if env_collision[0]:
		var collision_dir = env_collision[1]
		var collision_point = env_collision[2]
		var unit_env_collider = env_collision[3]
		scene.conditional_log("check_collision collided: " + str(collider) + " check-directions: " + str(collision_direction) + " direction: " + scene.Constants.Direction.keys()[env_collision[1]] + ", at " + str(collision_point) + " w/ env-collider: " + str(unit_env_collider[0]))
		check_ground_collision(unit, collider, collision_point, unit_env_collider, delta)
		if collision_dir == scene.Constants.Direction.UP:
			scene.conditional_log("check_collision up collision zero-out v-speed")
			unit.v_speed = 0
			var collider_set_pos_y = collision_point.y - scene.Constants.QUANTUM_DIST
			var unit_env_collider_y_delta = unit_env_collider[0].y
			if unit_is_shortened(unit):
				unit_env_collider_y_delta *= scene.Constants.CROUCH_FACTOR
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider_y_delta)
			scene.conditional_log("check_collision up collision change-pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
			unit.pos.y = unit.pos.y + y_dist_to_translate
			if unit.get_current_action() == scene.Constants.UnitCurrentAction.JUMPING:
				unit.set_current_action(scene.Constants.UnitCurrentAction.IDLE)
			elif unit.get_current_action() == scene.Constants.UnitCurrentAction.FLYING:
				unit.set_current_action(scene.Constants.UnitCurrentAction.FLYING_CEILING)
		elif collision_dir == scene.Constants.Direction.LEFT or collision_dir == scene.Constants.Direction.RIGHT:
			if (collider[0].x == collider[1].x
			or (unit.no_gravity or not unit.unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND])):
				scene.conditional_log("check_collision left/right non-slope-collision or not-grounded zero-out h-speed")
				unit.h_speed = 0
			var collider_set_pos_x = collision_point.x
			if collision_dir == scene.Constants.Direction.LEFT:
				scene.conditional_log("check_collision left collision")
				collider_set_pos_x = collider_set_pos_x + scene.Constants.QUANTUM_DIST
			else:
				scene.conditional_log("check_collision right collision")
				collider_set_pos_x = collider_set_pos_x - scene.Constants.QUANTUM_DIST
			var x_dist_to_translate = collider_set_pos_x - (unit.pos.x + unit_env_collider[0].x)
			scene.conditional_log("check_collision change-pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
			unit.pos.x = unit.pos.x + x_dist_to_translate
			if collider[0].x == collider[1].x:
				unit.wall_collision() # subclass implementation

# handle collision with ground if any
func check_ground_collision(unit : Unit, collider, collision_point : Vector2, unit_env_collider, delta):
	if not unit_env_collider[1].has(scene.Constants.Direction.DOWN):
		scene.conditional_log("check_ground_collision " + str(unit_env_collider[0]) + " not ground collider")
		return
	if ((not unit.no_gravity
	and not unit.unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]
	or unit.no_gravity)
	and (collider[0].y == collider[1].y or (collider[0].x != collider[1].x and collider[0].y != collider[1].y))):
			scene.conditional_log("check_ground_collision airborne ground collision on: " + str(collider) + " with " + str(unit_env_collider[0]))
			unit.set_unit_condition(scene.Constants.UnitCondition.IS_ON_GROUND, true)
			if unit.get_current_action() == scene.Constants.UnitCurrentAction.JUMPING:
				if unit.h_speed == 0:
					# hit wall
					 unit.set_unit_condition(scene.Constants.UnitCondition.IS_ON_GROUND, false)
				else:
					# don't lose any of the 2 components of velocity
					var magnitude = sqrt(pow(unit.v_speed, 2) + pow(unit.h_speed, 2))
					unit.v_speed = -magnitude
					if unit.facing == scene.Constants.Direction.RIGHT:
						unit.h_speed = scene.Constants.QUANTUM_DIST
					else:
						unit.h_speed = -scene.Constants.QUANTUM_DIST
			else:
				# only keep the horizontal component of velocity
				unit.v_speed = -1 * abs(unit.h_speed)
				if unit.h_speed > 0:
					unit.h_speed = scene.Constants.QUANTUM_DIST
				else:
					unit.h_speed = -1 * scene.Constants.QUANTUM_DIST
			scene.conditional_log("check_ground_collision change move speed's to ground movement: (" + str(unit.h_speed) + ", " + str(unit.v_speed) + ")")
			var collider_set_pos_y = collision_point.y + scene.Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			scene.conditional_log("check_ground_collision change pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
			unit.pos.y = unit.pos.y + y_dist_to_translate
			var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
			scene.conditional_log("check_ground_collision change pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
			unit.pos.x = unit.pos.x + x_dist_to_translate
			scene.conditional_log("check_ground_collision set grounded")
			if not unit.no_gravity:
				if unit.get_current_action() == scene.Constants.UnitCurrentAction.FLYING:
					scene.conditional_log("check_ground_collision set current action flying -> idle")
					unit.set_current_action(scene.Constants.UnitCurrentAction.IDLE)
				if unit.unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]:
					interact_grounded(unit, delta)
		
	

# returns true/false, collision direction, collision point, and unit env collider
func unit_is_colliding_w_env(unit : Unit, collider, direction, delta, grounded_check = false):
	if (((direction == scene.Constants.Direction.LEFT or direction == scene.Constants.Direction.RIGHT)
	and collider[0].y == collider[1].y)
	or ((direction == scene.Constants.Direction.UP or direction == scene.Constants.Direction.DOWN)
	and collider[0].x == collider[1].x)):
		return [false, -1, Vector2(), {}]
	for unit_env_collider in scene.Constants.ENV_COLLIDERS[unit.unit_type]:
		if not unit_env_collider[1].has(direction):
			continue
		if ((direction == scene.Constants.Direction.LEFT or direction == scene.Constants.Direction.RIGHT)
		and (collider[0].x != collider[1].x and collider[0].y != collider[1].y)
		and unit_env_collider[0] != Vector2(0, 0)):
			continue;
		var intersects_results = intersect_check_w_collider_uec_dir(unit, collider, direction, unit_env_collider, grounded_check, delta)
		if intersects_results[0]:
			scene.conditional_log("unit_is_colliding_w_env collection detected with collider " + str(collider) + ", direction " + scene.Constants.Direction.keys()[direction] + ", grounded_check " + str(grounded_check))
			return [intersects_results[0], direction, intersects_results[1], unit_env_collider]
	return [false, -1, Vector2(), {}]

func intersect_check_w_collider_uec_dir(unit : Unit, collider, direction_to_check : int, unit_env_collider, grounded_check : bool, delta):
	var unit_env_collider_vector = unit_env_collider[0]
	if unit_is_shortened(unit):
		unit_env_collider_vector.y = unit_env_collider_vector.y * scene.Constants.CROUCH_FACTOR
	var collision_check : Vector2 = unit.pos + unit_env_collider_vector
	var altered_collision_check: Vector2 = collision_check
	if grounded_check:
		altered_collision_check.y = altered_collision_check.y + .9
	return GameUtils.path_intersects_border(
		altered_collision_check,
		collision_check + Vector2(unit.h_speed * delta, unit.v_speed * delta),
		collider[0],
		collider[1])

func unit_is_shortened(unit : Unit):
	return (unit.get_current_action() == scene.Constants.UnitCurrentAction.CROUCHING
		or unit.get_current_action() == scene.Constants.UnitCurrentAction.SLIDING
		or unit.get_current_action() == scene.Constants.UnitCurrentAction.FLYING or unit.get_current_action() == scene.Constants.UnitCurrentAction.FLYING_CEILING)

func interact_post(unit : Unit):
	# need to reground unit in case it ended up somewhere underneath ground level
	if not unit.no_gravity and unit.unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]:
		# gravity-affected, grounded
		scene.conditional_log("interact_post gravity-affected, grounded - ground_placement")
		ground_placement(unit)
