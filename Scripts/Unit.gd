extends Node2D

class_name Unit


const Constants = preload("res://Scripts/Constants.gd")
const GameUtils = preload("res://Scripts/GameUtils.gd")
const UnitExplode = preload("res://FX/UnitExplode.tscn")

export var unit_type : int
var hit_box
var health : int
var active : bool = true

var actions = {}
var unit_conditions = {}
var timer_actions = {}
var facing : int
var current_action_time_elapsed : float = 0
var unit_condition_timers = {}

var pos : Vector2
var h_speed : float = 0
var v_speed : float = 0
var target_move_speed : float
var last_contacted_ground_collider : Array

# [active, x, y, width, height], assuming right-facing
var melee_hit_box = [false, 0, 0, 0, 0]
var melee_hit : bool

var current_sprite : Node2D

var time_elapsed : float
var is_flash : bool = false
var flash_start_timestamp : float

var scene

const DEFEATED_KNOCKBACK = 15
var defeated_time_elapsed : float

# Called when the node enters the scene tree for the first time
func _ready():
	for child in get_children():
		child.visible = false

func init_unit_w_scene(scene):
	self.scene = scene
	for action_num in Constants.UNIT_TYPE_ACTIONS[unit_type]:
		actions[action_num] = false
	for condition_num in Constants.UNIT_TYPE_CONDITIONS[unit_type].keys():
		set_unit_condition(condition_num, Constants.UNIT_TYPE_CONDITIONS[unit_type][condition_num])
	for condition_num in Constants.UNIT_CONDITION_TIMERS[unit_type].keys():
		unit_condition_timers[condition_num] = 0
	for timer_action_num in Constants.ACTION_TIMERS[unit_type].keys():
		timer_actions[timer_action_num] = 0
	hit_box = Constants.UNIT_HIT_BOXES[unit_type]
	facing = Constants.Direction.RIGHT
	scale.x = Constants.SCALE_FACTOR
	scale.y = Constants.SCALE_FACTOR
	health = Constants.UNIT_TYPE_HEALTH[unit_type]

func set_action(action : int):
	assert(action in Constants.UNIT_TYPE_ACTIONS[unit_type])
	actions[action] = true

func set_timer_action(action : int):
	assert(action in Constants.UNIT_TYPE_ACTIONS[unit_type])
	assert(action in Constants.ACTION_TIMERS[unit_type].keys())
	timer_actions[action] = Constants.ACTION_TIMERS[unit_type][action]

func reset_timer_action(action : int):
	assert(action in Constants.UNIT_TYPE_ACTIONS[unit_type])
	assert(action in Constants.ACTION_TIMERS[unit_type].keys())
	timer_actions[action] = 0

func set_unit_condition(condition_type : int, condition):
	assert(condition_type in Constants.UNIT_TYPE_CONDITIONS[unit_type].keys())
	unit_conditions[condition_type] = condition

func set_unit_condition_with_timer(condition_type : int):
	assert(condition_type in Constants.UNIT_CONDITION_TIMERS[unit_type].keys())
	set_unit_condition(condition_type, Constants.UNIT_CONDITION_TIMERS[unit_type][condition_type][1])
	unit_condition_timers[condition_type] = Constants.UNIT_CONDITION_TIMERS[unit_type][condition_type][0]

func get_condition(condition_num : int, default):
	if condition_num in Constants.UNIT_TYPE_CONDITIONS[unit_type].keys():
		return unit_conditions[condition_num]
	else:
		return default

func is_current_action_timer_done(current_action : int):
	assert(current_action in Constants.CURRENT_ACTION_TIMERS[unit_type].keys())
	return current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][current_action]

func melee_attack_check():
	# implemented in subclass
	pass

func hit_check():
	# implemented in subclass
	pass

func collision_with(other_unit : Unit):
	var own_hit_box = Constants.UNIT_HIT_BOXES[unit_type]
	var other_hit_box = Constants.UNIT_HIT_BOXES[other_unit.unit_type]
	var own_y_factor = 1
	if is_shortened():
		own_y_factor = Constants.CROUCH_FACTOR
	var other_y_factor = 1
	if other_unit.is_shortened():
		other_y_factor = Constants.CROUCH_FACTOR
	return GameUtils.check_hitbox_collision(
		pos.y + own_hit_box[Constants.HIT_BOX_BOUND.UPPER_BOUND] * own_y_factor,
		pos.y + own_hit_box[Constants.HIT_BOX_BOUND.LOWER_BOUND],
		pos.x + own_hit_box[Constants.HIT_BOX_BOUND.LEFT_BOUND],
		pos.x + own_hit_box[Constants.HIT_BOX_BOUND.RIGHT_BOUND],
		other_unit.pos.y + other_hit_box[Constants.HIT_BOX_BOUND.UPPER_BOUND] * other_y_factor,
		other_unit.pos.y + other_hit_box[Constants.HIT_BOX_BOUND.LOWER_BOUND],
		other_unit.pos.x + other_hit_box[Constants.HIT_BOX_BOUND.LEFT_BOUND],
		other_unit.pos.x + other_hit_box[Constants.HIT_BOX_BOUND.RIGHT_BOUND])

func reset_actions():
	for action_num in Constants.UNIT_TYPE_ACTIONS[unit_type]:
		actions[action_num] = false

func do_with_timeout(action : int, new_current_action : int = -1):
	if timer_actions[action] == 0:
		set_action(action)
		set_timer_action(action)
		if new_current_action != -1:
			set_current_action(new_current_action)

func handle_input(delta):
	# implemented in subclass
	pass

func reset_current_action():
	# process CURRENT_ACTION
	if get_current_action() == Constants.UnitCurrentAction.JUMPING:
		if not actions[Constants.ActionType.JUMP]:
			set_current_action(Constants.UnitCurrentAction.IDLE)
	# process MOVING_STATUS
	if not actions[Constants.ActionType.MOVE] and not (Constants.UNIT_TYPE_ACTIONS[unit_type].find(Constants.ActionType.DASH) != -1 and actions[Constants.ActionType.DASH]):
		set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)

func process_unit(delta, time_elapsed : float, scene):
	current_action_time_elapsed += delta
	melee_attack_check()
	hit_check()
	process_current_action_melee()
	execute_actions(delta, scene)
	handle_idle()
	handle_moving_status(delta)
	advance_timers(delta)
	reset_current_action()
	self.time_elapsed = time_elapsed

func advance_timers(delta):
	for timer_action_num in Constants.ACTION_TIMERS[unit_type].keys():
		timer_actions[timer_action_num] = move_toward(timer_actions[timer_action_num], 0, delta)
	for condition_num in Constants.UNIT_CONDITION_TIMERS[unit_type].keys():
		unit_condition_timers[condition_num] = move_toward(unit_condition_timers[condition_num], 0, delta)
		if unit_condition_timers[condition_num] == 0:
			set_unit_condition(condition_num, Constants.UNIT_CONDITION_TIMERS[unit_type][condition_num][2])

func get_current_action():
	return unit_conditions[Constants.UnitCondition.CURRENT_ACTION]

func set_current_action(current_action : int):
	assert(current_action in Constants.UNIT_TYPE_CURRENT_ACTIONS[unit_type])
	if get_current_action() != current_action:
		current_action_time_elapsed = 0
	set_unit_condition(Constants.UnitCondition.CURRENT_ACTION, current_action)

func execute_actions(delta, scene):
	for action_num in Constants.UNIT_TYPE_ACTIONS[unit_type]:
		if !actions[action_num]:
			continue
		match action_num:
			Constants.ActionType.JUMP:
				jump()
			Constants.ActionType.MOVE:
				move()
				
func process_current_action_melee():
	if Constants.CURRENT_ACTION_HAS_MELEE_HITBOX[get_current_action()]:
		for i in range (Constants.UNIT_MELEE_HIT_BOXES[unit_type][get_current_action()].size()):
			var current_action_hit_box = Constants.UNIT_MELEE_HIT_BOXES[unit_type][get_current_action()][Constants.UNIT_MELEE_HIT_BOXES[unit_type][get_current_action()].size() - 1 - i]
			if current_action_time_elapsed >= current_action_hit_box[0]:
				melee_hit_box[0] = true
				if facing == Constants.Direction.RIGHT:
					melee_hit_box[1] = pos.x + current_action_hit_box[1]
				else:
					melee_hit_box[1] = pos.x - current_action_hit_box[1] - current_action_hit_box[3]
				melee_hit_box[2] = pos.y + current_action_hit_box[2]
				melee_hit_box[3] = current_action_hit_box[3]
				melee_hit_box[4] = current_action_hit_box[4]
				break
	else:
		melee_hit_box[0] = false
	pass

func jump():
	set_current_action(Constants.UnitCurrentAction.JUMPING)
	var jump_speed = Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type]
	if (unit_conditions[Constants.UnitCondition.IS_ON_GROUND]):
		# hit ground
		v_speed = max(jump_speed, v_speed)
	else:
		# airborne
		v_speed = max(Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type], move_toward(v_speed, Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type], get_process_delta_time() * Constants.GRAVITY))
	set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)
	if get_current_action() == Constants.UnitCurrentAction.JUMPING and v_speed > 0:
		set_sprite("Jump", 0)
	if is_current_action_timer_done(Constants.UnitCurrentAction.JUMPING):
		set_current_action(Constants.UnitCurrentAction.IDLE)
		

func move():
	set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.MOVING)
	target_move_speed = Constants.UNIT_TYPE_MOVE_SPEEDS[unit_type]
	if (get_current_action() == Constants.UnitCurrentAction.IDLE
	and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]):
		set_sprite("Walk")

func handle_moving_status(delta):
	# what we have: facing, current speed, move status, grounded
	# we want: to set the new intended speed
	var magnitude : float
	if unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		magnitude = sqrt(pow(v_speed, 2) + pow(h_speed, 2))
	else:
		magnitude = abs(h_speed)
	
	# if move status is idle
	if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
		# slow down
		magnitude = move_toward(magnitude, 0, Constants.ACCELERATION * delta)
	# if move status is not idle
	else:
		# if is facing-aligned
		if (h_speed <= 0 and facing == Constants.Direction.LEFT) or (h_speed >= 0 and facing == Constants.Direction.RIGHT):
			# speed up
			magnitude = move_toward(magnitude, target_move_speed, Constants.ACCELERATION * delta)
		# if is not facing-aligned
		else:
			# slow down
			magnitude = move_toward(magnitude, 0, Constants.ACCELERATION * delta)
	
	# if is grounded
	if unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		# make magnitude greater than quantum distance
		if magnitude > 0 and magnitude < Constants.QUANTUM_DIST:
			magnitude = Constants.QUANTUM_DIST * 2
		
		# make move vector point down
		if magnitude > 0:
			if h_speed > 0:
				h_speed = Constants.QUANTUM_DIST # preserve h direction
			elif h_speed < 0:
				h_speed = -1 * Constants.QUANTUM_DIST
			else:
				# from still to moving
				if facing == Constants.Direction.RIGHT:
					h_speed = Constants.QUANTUM_DIST
				else:
					h_speed = -1 * Constants.QUANTUM_DIST
		else:
			h_speed = 0
		v_speed = -1 * magnitude
	# if is not grounded
	else:
		# set h_speed
		if magnitude > 0:
			if h_speed > 0:
				h_speed = magnitude
			elif h_speed < 0:
				h_speed = -1 * magnitude
			else:
				# from no lateral movement to having lateral movement
				if facing == Constants.Direction.RIGHT:
					h_speed = magnitude
				else:
					h_speed = -1 * magnitude
		else:
			h_speed = 0

func handle_idle():
	if get_current_action() == Constants.UnitCurrentAction.IDLE:
		if unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
				set_sprite("Idle")
		elif v_speed > 0:
			set_sprite("Jump", 0)
		else:
			set_sprite("Jump", 1)

func set_sprite(sprite_class : String, index : int = 0):
	if not unit_type in Constants.UNIT_SPRITES or not sprite_class in Constants.UNIT_SPRITES[unit_type]:
		return
	var node_list = Constants.UNIT_SPRITES[unit_type][sprite_class][1]
	var true_index : int = index
	if true_index > len(node_list) - 1:
		true_index = 0
	var new_sprite : Node2D = get_node(node_list[true_index])
	if (is_flash):
		if int((time_elapsed - flash_start_timestamp) / Constants.FLASH_CYCLE) % 2 == 1:
			new_sprite.set_modulate(Color(2, 1, 1))
		else:
			new_sprite.set_modulate(Color(1, .5, .5))
	else:
		new_sprite.set_modulate(Color(1, 1, 1))
	if current_sprite == null or current_sprite != new_sprite:
		if current_sprite != null:
			current_sprite.visible = false
		current_sprite = new_sprite
		current_sprite.visible = true
		if (Constants.UNIT_SPRITES[unit_type][sprite_class][0]):
			current_sprite.set_frame(0)
			current_sprite.play()
	if facing == Constants.Direction.LEFT:
		current_sprite.scale.x = -1
	else:
		current_sprite.scale.x = 1

func react(delta):
	pos.x = pos.x + h_speed * delta
	pos.y = pos.y + v_speed * delta
	position.x = pos.x * Constants.GRID_SIZE * Constants.SCALE_FACTOR
	position.y = -1 * pos.y * Constants.GRID_SIZE * Constants.SCALE_FACTOR

func unit_death_hook():
	pass

func death_check():
	if health == 0:
		reset_actions()
		reset_current_action()
		scene.units.erase(self)
		scene.inactive_units.append(self)
		active = false
		if (unit_type != Constants.UnitType.PLAYER):
			set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)
			set_current_action(Constants.UnitCurrentAction.IDLE)
			v_speed = DEFEATED_KNOCKBACK
			if facing == Constants.Direction.RIGHT:
				h_speed = -DEFEATED_KNOCKBACK
			else:
				h_speed = DEFEATED_KNOCKBACK
			defeated_time_elapsed = time_elapsed

func death_cleanup():
	if time_elapsed - defeated_time_elapsed >= Constants.DEFEATED_LIFETIME:
		scene.inactive_units.erase(self)
		var unit_explode : AnimatedSprite = UnitExplode.instance()
		scene.add_child(unit_explode)
		unit_explode.position = position
		unit_explode.scale.x = Constants.SCALE_FACTOR
		unit_explode.scale.y = Constants.SCALE_FACTOR
		unit_explode.frame = 0
		unit_death_hook()
		queue_free()

func hit(damage : int, dir : int):
	health = max(0, health - damage)

func build_iframe_texture(image : Image):
	image.lock()
	for y in image.get_height():
		for x in image.get_width():
			var color_html : String = image.get_pixel(x, y).to_html(false)
			if Constants.UNIT_FLASH_MAPPINGS[unit_type].has(color_html):
				image.set_pixel(x, y, Constants.UNIT_FLASH_MAPPINGS[unit_type][color_html])
	image.unlock()
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image, 0)
	return new_texture

func wall_collision():
	# implemented in subclass
	pass

func is_shortened():
	# implemented in subclass
	return false

func log_unit():
	print("===UNIT DEBUG====")
	print("pos: " + str(pos))
	print("speeds: " + str(Vector2(h_speed, v_speed)))
	print("facing: " + Constants.Direction.keys()[facing])
	print("conditions: action: " + Constants.UnitCurrentAction.keys()[get_current_action()] + ", grounded: " + str(unit_conditions[Constants.UnitCondition.IS_ON_GROUND]) + ", movement: " + Constants.UnitMovingStatus.keys()[unit_conditions[Constants.UnitCondition.MOVING_STATUS]])
	print("=================")
