extends Node2D

class_name Unit


const GameUtils = preload("res://Scripts/GameUtils.gd")

export var unit_type : int
var no_gravity : bool = false # whether gravity should affect this unit
var hit_box

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
var last_contacted_collider : Array

var current_sprite : Node2D

var time_elapsed : float
var is_flash : bool = false
var flash_start_timestamp : float

var scene

# Called when the node enters the scene tree for the first time
func _ready():
	for child in get_children():
		child.visible = false

func init_unit_w_scene(scene):
	self.scene = scene
	for action_num in scene.Constants.UNIT_TYPE_ACTIONS[unit_type]:
		actions[action_num] = false
	for condition_num in scene.Constants.UNIT_TYPE_CONDITIONS[unit_type].keys():
		set_unit_condition(condition_num, scene.Constants.UNIT_TYPE_CONDITIONS[unit_type][condition_num])
	for condition_num in scene.Constants.UNIT_CONDITION_TIMERS[unit_type].keys():
		unit_condition_timers[condition_num] = 0
	for timer_action_num in scene.Constants.ACTION_TIMERS[unit_type].keys():
		timer_actions[timer_action_num] = 0
	hit_box = scene.Constants.UNIT_HIT_BOXES[unit_type]
	build_iframe_sprites()
	facing = scene.Constants.Direction.RIGHT
	scale.x = scene.Constants.SCALE_FACTOR
	scale.y = scene.Constants.SCALE_FACTOR

func set_action(action : int):
	assert(action in scene.Constants.UNIT_TYPE_ACTIONS[unit_type])
	actions[action] = true

func set_timer_action(action : int):
	assert(action in scene.Constants.UNIT_TYPE_ACTIONS[unit_type])
	assert(action in scene.Constants.ACTION_TIMERS[unit_type].keys())
	if unit_type == scene.Constants.UnitType.PLAYER:
		if action == scene.Constants.ActionType.FLOAT:
			timer_actions[action] = scene.player_float_cooldown
			return
		elif action == scene.Constants.ActionType.DASH:
			timer_actions[action] = scene.player_dash_window
			return
	timer_actions[action] = scene.Constants.ACTION_TIMERS[unit_type][action]

func reset_timer_action(action : int):
	assert(action in scene.Constants.UNIT_TYPE_ACTIONS[unit_type])
	assert(action in scene.Constants.ACTION_TIMERS[unit_type].keys())
	timer_actions[action] = 0

func set_unit_condition(condition_type : int, condition):
	assert(condition_type in scene.Constants.UNIT_TYPE_CONDITIONS[unit_type].keys())
	unit_conditions[condition_type] = condition

func set_unit_condition_with_timer(condition_type : int):
	assert(condition_type in scene.Constants.UNIT_CONDITION_TIMERS[unit_type].keys())
	set_unit_condition(condition_type, scene.Constants.UNIT_CONDITION_TIMERS[unit_type][condition_type][1])
	if unit_type == scene.Constants.UnitType.PLAYER and condition_type == scene.Constants.UnitCondition.IS_INVINCIBLE:
		unit_condition_timers[condition_type] = scene.player_invincible_duration
		return
	unit_condition_timers[condition_type] = scene.Constants.UNIT_CONDITION_TIMERS[unit_type][condition_type][0]

func get_condition(condition_num : int, default):
	if condition_num in scene.Constants.UNIT_TYPE_CONDITIONS[unit_type].keys():
		return unit_conditions[condition_num]
	else:
		return default

func is_current_action_timer_done(current_action : int):
	assert(current_action in scene.Constants.CURRENT_ACTION_TIMERS[unit_type].keys())
	return current_action_time_elapsed >= scene.Constants.CURRENT_ACTION_TIMERS[unit_type][current_action]

func hit_check():
	# implemented in subclass
	pass

func reset_actions():
	for action_num in scene.Constants.UNIT_TYPE_ACTIONS[unit_type]:
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
	if get_current_action() == scene.Constants.UnitCurrentAction.JUMPING:
		if not actions[scene.Constants.ActionType.JUMP]:
			set_current_action(scene.Constants.UnitCurrentAction.IDLE)
	# process MOVING_STATUS
	if not actions[scene.Constants.ActionType.MOVE]:
		set_unit_condition(scene.Constants.UnitCondition.MOVING_STATUS, scene.Constants.UnitMovingStatus.IDLE)

func process_unit(delta, time_elapsed : float, scene):
	current_action_time_elapsed += delta
	execute_actions(delta, scene)
	handle_idle()
	handle_moving_status(delta, scene)
	advance_timers(delta)
	self.time_elapsed = time_elapsed

func advance_timers(delta):
	for timer_action_num in scene.Constants.ACTION_TIMERS[unit_type].keys():
		timer_actions[timer_action_num] = move_toward(timer_actions[timer_action_num], 0, delta)
	for condition_num in scene.Constants.UNIT_CONDITION_TIMERS[unit_type].keys():
		unit_condition_timers[condition_num] = move_toward(unit_condition_timers[condition_num], 0, delta)
		if unit_condition_timers[condition_num] == 0:
			set_unit_condition(condition_num, scene.Constants.UNIT_CONDITION_TIMERS[unit_type][condition_num][2])

func get_current_action():
	return unit_conditions[scene.Constants.UnitCondition.CURRENT_ACTION]

func set_current_action(current_action : int):
	assert(current_action in scene.Constants.UNIT_TYPE_CURRENT_ACTIONS[unit_type])
	if get_current_action() != current_action:
		current_action_time_elapsed = 0
	set_unit_condition(scene.Constants.UnitCondition.CURRENT_ACTION, current_action)

func execute_actions(delta, scene):
	for action_num in scene.Constants.UNIT_TYPE_ACTIONS[unit_type]:
		if !actions[action_num]:
			continue
		match action_num:
			scene.Constants.ActionType.JUMP:
				jump()
			scene.Constants.ActionType.MOVE:
				move()

func jump():
	set_current_action(scene.Constants.UnitCurrentAction.JUMPING)
	var jump_speed
	if unit_type == scene.Constants.UnitType.PLAYER:
		jump_speed = scene.player_jump_speed
	else:
		jump_speed = scene.Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type]
	if (unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]):
		# hit ground
		v_speed = max(jump_speed, v_speed)
	else:
		# airborne
		v_speed = max(scene.Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type], move_toward(v_speed, scene.Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type], get_process_delta_time() * scene.Constants.GRAVITY))
	set_unit_condition(scene.Constants.UnitCondition.IS_ON_GROUND, false)
	if get_current_action() == scene.Constants.UnitCurrentAction.JUMPING and v_speed > 0:
		set_sprite("Jump", 0)
	if is_current_action_timer_done(scene.Constants.UnitCurrentAction.JUMPING):
		set_current_action(scene.Constants.UnitCurrentAction.IDLE)
		

func move():
	set_unit_condition(scene.Constants.UnitCondition.MOVING_STATUS, scene.Constants.UnitMovingStatus.MOVING)
	if unit_type == scene.Constants.UnitType.PLAYER:
		target_move_speed = scene.player_move_speed
	else:
		target_move_speed = scene.Constants.UNIT_TYPE_MOVE_SPEEDS[unit_type]
	if (get_current_action() == scene.Constants.UnitCurrentAction.IDLE
	and unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]):
		set_sprite("Walk")

func handle_moving_status(delta, scene):
	# what we have: facing, current speed, move status, grounded
	# we want: to set the new intended speed
	var magnitude : float
	if not no_gravity and unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]:
		magnitude = sqrt(pow(v_speed, 2) + pow(h_speed, 2))
	else:
		magnitude = abs(h_speed)
	scene.conditional_log("set magnitude: " + str(magnitude))
	
	# if move status is idle
	if unit_conditions[scene.Constants.UnitCondition.MOVING_STATUS] == scene.Constants.UnitMovingStatus.IDLE:
		# slow down
		magnitude = move_toward(magnitude, 0, scene.move_acceleration * delta)
		scene.conditional_log("move-idle, not-near-still: slow-down: magnitude: " + str(magnitude))
	# if move status is not idle
	else:
		# if is facing-aligned
		if (h_speed <= 0 and facing == scene.Constants.Direction.LEFT) or (h_speed >= 0 and facing == scene.Constants.Direction.RIGHT):
			# speed up
			magnitude = move_toward(magnitude, target_move_speed, scene.move_acceleration * delta)
			scene.conditional_log("not-move-idle, facing-aligned: speed-up: magnitude: " + str(magnitude))
		# if is not facing-aligned
		else:
			# slow down
			magnitude = move_toward(magnitude, 0, scene.move_acceleration * delta)
			scene.conditional_log("not-move-idle, not-facing-aligned: slow-down: magnitude: " + str(magnitude))
	
	# if is grounded
	if not no_gravity and unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]:
		# make magnitude greater than quantum distance
		if magnitude > 0 and magnitude < scene.Constants.QUANTUM_DIST:
			magnitude = scene.Constants.QUANTUM_DIST * 2
			scene.conditional_log("grounded: quantum magnitude: " + str(magnitude))
		
		# make move vector point down
		if magnitude > 0:
			if h_speed > 0:
				h_speed = scene.Constants.QUANTUM_DIST # preserve h direction
			elif h_speed < 0:
				h_speed = -1 * scene.Constants.QUANTUM_DIST
			else:
				if facing == scene.Constants.Direction.RIGHT:
					h_speed = scene.Constants.QUANTUM_DIST
				else:
					h_speed = -1 * scene.Constants.QUANTUM_DIST
			scene.conditional_log("grounded, non-zero-magnitude: preserve-h-dir: " + str(h_speed))
		else:
			h_speed = 0
		v_speed = -1 * magnitude
		scene.conditional_log("grounded: point-down: " + str(v_speed) + ", set-h-speed: " + str(h_speed))
	# if is not grounded
	else:
		# set h_speed
		if magnitude > 0:
			if h_speed > 0:
				h_speed = magnitude
			elif h_speed < 0:
				h_speed = -1 * magnitude
			else:
				if facing == scene.Constants.Direction.RIGHT:
					h_speed = magnitude
				else:
					h_speed = -1 * magnitude
		else:
			h_speed = 0

func handle_idle():
	if get_current_action() == scene.Constants.UnitCurrentAction.IDLE:
		if not no_gravity:
			if unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]:
				if unit_conditions[scene.Constants.UnitCondition.MOVING_STATUS] == scene.Constants.UnitMovingStatus.IDLE:
					set_sprite("Idle")
			elif v_speed > 0:
				set_sprite("Jump", 0)
			else:
				set_sprite("Jump", 1)
		else:
			set_sprite("Idle")

func set_sprite(sprite_class : String, index : int = 0):
	if not unit_type in scene.Constants.UNIT_SPRITES or not sprite_class in scene.Constants.UNIT_SPRITES[unit_type]:
		return
	var node_list = scene.Constants.UNIT_SPRITES[unit_type][sprite_class][1]
	var true_index : int = index
	if true_index > len(node_list) - 1:
		true_index = 0
	var new_sprite : Node2D
	if (is_flash):
		if int((time_elapsed - flash_start_timestamp) / scene.Constants.FLASH_CYCLE) % 2 == 1:
			new_sprite = get_node(node_list[true_index] + "Flash")
		else:
			new_sprite = get_node(node_list[true_index])
	else:
		new_sprite = get_node(node_list[true_index])
	if current_sprite == null or current_sprite != new_sprite:
		if current_sprite != null:
			current_sprite.visible = false
		current_sprite = new_sprite
		current_sprite.visible = true
		if (scene.Constants.UNIT_SPRITES[unit_type][sprite_class][0]):
			current_sprite.play()
	if facing == scene.Constants.Direction.LEFT:
		current_sprite.scale.x = -1
	else:
		current_sprite.scale.x = 1

func react(delta):
	pos.x = pos.x + h_speed * delta
	pos.y = pos.y + v_speed * delta
	position.x = pos.x * scene.Constants.GRID_SIZE * scene.Constants.SCALE_FACTOR
	position.y = -1 * pos.y * scene.Constants.GRID_SIZE * scene.Constants.SCALE_FACTOR

func hit(damage : int, dir : int):
	pass

func build_iframe_sprites():
	if not scene.Constants.UNIT_FLASH_MAPPINGS.keys().has(unit_type):
		return
	for child in get_children():
		if child is Sprite:
			var sprite_child : Sprite = child
			var new_sprite_child : Sprite = sprite_child.duplicate()
			add_child(new_sprite_child)
			new_sprite_child.name = sprite_child.name + "Flash"
			var new_texture : ImageTexture = build_iframe_texture(new_sprite_child.texture.get_data())
			new_sprite_child.texture = new_texture
		elif child is AnimatedSprite:
			var animated_sprite_child : AnimatedSprite = child
			var new_animated_sprite_child : AnimatedSprite = animated_sprite_child.duplicate()
			add_child(new_animated_sprite_child)
			new_animated_sprite_child.name = animated_sprite_child.name + "Flash"
			var new_sprite_frames : SpriteFrames = new_animated_sprite_child.frames.duplicate()
			new_animated_sprite_child.frames = new_sprite_frames
			for frame_num in range(new_sprite_frames.get_frame_count(new_animated_sprite_child.animation)):
				var new_texture : ImageTexture = build_iframe_texture(new_sprite_frames.get_frame(new_animated_sprite_child.animation, frame_num).get_data())
				new_sprite_frames.set_frame(new_animated_sprite_child.animation, frame_num, new_texture)

func build_iframe_texture(image : Image):
	image.lock()
	for y in image.get_height():
		for x in image.get_width():
			var color_html : String = image.get_pixel(x, y).to_html(false)
			if scene.Constants.UNIT_FLASH_MAPPINGS[unit_type].has(color_html):
				image.set_pixel(x, y, scene.Constants.UNIT_FLASH_MAPPINGS[unit_type][color_html])
	image.unlock()
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image, 0)
	return new_texture

func wall_collision():
	pass

func log_unit():
	print("===UNIT DEBUG====")
	print("pos: " + str(pos))
	print("speeds: " + str(Vector2(h_speed, v_speed)))
	print("facing: " + scene.Constants.Direction.keys()[facing])
	print("conditions: action: " + scene.Constants.UnitCurrentAction.keys()[get_current_action()] + ", grounded: " + str(unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]) + ", movement: " + scene.Constants.UnitMovingStatus.keys()[unit_conditions[scene.Constants.UnitCondition.MOVING_STATUS]])
	print("=================")
