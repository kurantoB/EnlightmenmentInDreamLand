extends Node

class_name GameScene

export var tile_set_name: String
export(Array, String) var tilemaps_to_scale
export(Array, String) var tilemaps_to_parallax_scroll

const Constants = preload("res://Scripts/Constants.gd")
const Unit = preload("res://Scripts/Unit.gd")

var units = []
var player : Player

# [pressed?, just pressed?, just released?]
var input_table = {
	Constants.PlayerInput.UP: [false, false, false],
	Constants.PlayerInput.DOWN: [false, false, false],
	Constants.PlayerInput.LEFT: [false, false, false],
	Constants.PlayerInput.RIGHT: [false, false, false],
	Constants.PlayerInput.GBA_A: [false, false, false],
	Constants.PlayerInput.GBA_B: [false, false, false],
	Constants.PlayerInput.GBA_SELECT: [false, false, false],
}
const I_T_PRESSED : int = 0
const I_T_JUST_PRESSED : int = 1
const I_T_JUST_RELEASED : int = 2

var stage_env

var time_elapsed : float = 0
var time_elapsed_to_log : float = -1
var num_iterations = 5
var log_triggered : bool = false

var player_cam : Camera2D

# Called when the node enters the scene tree for the first time.
func _ready():
	units.append(get_node("Player"))
	player = units[0]
	stage_env = load("res://Scripts/StageEnvironment.gd").new(self)
	player_cam = player.get_node("Camera2D")
	player_cam.make_current()
	get_node("AudioStreamPlayer").play()
	
	for tilemap_to_scale in tilemaps_to_scale:
		if has_node(tilemap_to_scale):
			var this_tilemap_to_scale = get_node(tilemap_to_scale)
			this_tilemap_to_scale.scale.x = Constants.SCALE_FACTOR
			this_tilemap_to_scale.scale.y = Constants.SCALE_FACTOR

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for unit in units:
		unit.reset_actions()
	handle_player_input()
	# handle enemy input
	for unit in units:
		unit.process_unit(delta, self)
		set_logging_iteration(unit, delta)
		stage_env.interact(unit, delta)
		unit.react(delta)
		stage_env.interact_post(unit)
		terminate_logging_iteration(unit)
		time_elapsed = time_elapsed + delta
	
	# visual effects
	for tilemap_to_parallax_scroll in tilemaps_to_parallax_scroll:
		if has_node(tilemap_to_parallax_scroll):
			var this_tilemap_to_parallax_scroll = get_node(tilemap_to_parallax_scroll)
			this_tilemap_to_parallax_scroll.position.x = player.position.x - player.position.x * Constants.PARALLAX_SCROLL_FACTOR
			this_tilemap_to_parallax_scroll.position.y = player.position.y - player.position.y * Constants.PARALLAX_SCROLL_FACTOR

func handle_player_input():
	for input_num in input_table.keys():
		if Input.is_action_pressed(Constants.INPUT_MAP[input_num]):
			input_table[input_num][I_T_PRESSED] = true
			input_table[input_num][I_T_JUST_RELEASED] = false
			if Input.is_action_just_pressed(Constants.INPUT_MAP[input_num]):
				input_table[input_num][I_T_JUST_PRESSED] = true
			else:
				input_table[input_num][I_T_JUST_PRESSED] = false
		else:
			input_table[input_num][I_T_PRESSED] = false
			input_table[input_num][I_T_JUST_PRESSED] = false
			if Input.is_action_just_released(Constants.INPUT_MAP[input_num]):
				input_table[input_num][I_T_JUST_RELEASED] = true
			else:
				input_table[input_num][I_T_JUST_RELEASED] = false
	
	# early exit
	
	if (player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.RECOILING
	or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING):
		return
	
	# process input_table

	if input_table[Constants.PlayerInput.UP][I_T_PRESSED]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			if not player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
				player.set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.do_with_timeout(Constants.ActionType.FLOAT, -1)
	
	if input_table[Constants.PlayerInput.DOWN][I_T_PRESSED]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE and player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				player.set_action(Constants.ActionType.DIGEST)
				player.set_unit_condition(Constants.UnitCondition.IS_PORTING, false)
				player.set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)
			else:
				player.set_action(Constants.ActionType.CROUCH)
				player.set_current_action(Constants.UnitCurrentAction.CROUCHING)
				player.set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
			player.set_action(Constants.ActionType.CROUCH)
	
	if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] or input_table[Constants.PlayerInput.RIGHT][I_T_PRESSED]:
		if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] and input_table[Constants.PlayerInput.RIGHT][I_T_PRESSED]:
			input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] = false
			input_table[Constants.PlayerInput.LEFT][I_T_JUST_PRESSED] = false
		var input_dir
		if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED]:
			input_dir = Constants.Direction.LEFT
		else:
			input_dir = Constants.Direction.RIGHT
		# if action-idle
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			# if action-idle + move-idle
			if player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
				# if action-idle + move-idle + grounded
				if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
					# if action-idle + move-idle + grounded + dash-timer-active + input-dash-facing-match
					if player.timer_actions[Constants.ActionType.DASH] > 0 and player.dash_facing == input_dir:
						# set dash
						player.handle_input_dash()
					# if action-idle + move-idle + grounded + (not-dash-timer-active or not-input-dash-facing-match)
					else:
						# set move
						player.handle_input_move()
					# start timer, set dash-facing
					player.set_timer_action(Constants.ActionType.DASH)
					player.dash_facing = input_dir
				# if action-idle + move-idle + not-grounded
				else:
					# set move, kill timer
					player.handle_input_move()
					player.reset_timer_action(Constants.ActionType.DASH)
			# if action-idle + move-moving
			elif player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.MOVING:
				# set move
				player.handle_input_move()
				# if action-idle + move-moving + grounded
				if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
					player.set_timer_action(Constants.ActionType.DASH)
					player.dash_facing = input_dir
				# if action-idle + move-moving + not-grounded
				else:
					# kill timer
					player.reset_timer_action(Constants.ActionType.DASH)
			# if action-idle + move-dashing
			else:
				# if action-idle + move-dashing + facing-change
				if player.facing != input_dir:
					# set move
					player.handle_input_move()
				# if action-idle + move-dashing + not-facing-change
				else:
					# set dash
					player.handle_input_dash()
				# start timer, set dash-facing
				player.set_timer_action(Constants.ActionType.DASH)
				player.dash_facing = input_dir
		# if action-jumping or action-flying
		elif (player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING
			or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING):
			# set move, kill timer
			player.handle_input_move()
			player.reset_timer_action(Constants.ActionType.DASH)
		# set facing
		player.facing = input_dir
	
	if input_table[Constants.PlayerInput.GBA_A][I_T_PRESSED]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING and input_table[Constants.PlayerInput.GBA_A][I_T_JUST_PRESSED]:
			player.do_with_timeout(Constants.ActionType.SLIDE, Constants.UnitCurrentAction.SLIDING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
			player.set_action(Constants.ActionType.JUMP)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
				if input_table[Constants.PlayerInput.GBA_A][I_T_JUST_PRESSED]:
					player.set_action(Constants.ActionType.JUMP)
					player.set_current_action(Constants.UnitCurrentAction.JUMPING)
					player.set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)
			elif not player.unit_conditions[Constants.UnitCondition.IS_PORTING] and input_table[Constants.PlayerInput.GBA_A][I_T_JUST_PRESSED]:
				player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.do_with_timeout(Constants.ActionType.FLOAT, -1)
	
	if input_table[Constants.PlayerInput.GBA_B][I_T_PRESSED]:
		# if crouching
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING and input_table[Constants.PlayerInput.GBA_B][I_T_JUST_PRESSED]:
			# slide
			player.do_with_timeout(Constants.ActionType.SLIDE, Constants.UnitCurrentAction.SLIDING)
		# else if idle or channeling
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CHANNELING:
			# if porting and B is not still pressed after absorb
			if player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				# drop porting
				player.set_action(Constants.ActionType.DROP_PORTING)
				player.set_unit_condition(Constants.UnitCondition.IS_PORTING, false)
			else:
				# channel
				player.set_action(Constants.ActionType.CHANNEL)
				player.set_current_action(Constants.UnitCurrentAction.CHANNELING)
				player.set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)
		# else if flying
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.set_action(Constants.ActionType.CANCEL_FLYING)
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
	
	if (input_table[Constants.PlayerInput.GBA_SELECT][I_T_JUST_PRESSED]
	and player.unit_conditions[Constants.UnitCondition.HAS_ABILITY]
	and player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.CHANNELING
	and player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.SLIDING):
		player.set_action(Constants.ActionType.DISCARD)
		player.set_unit_condition(Constants.UnitCondition.HAS_ABILITY, false)
	
	# process CURRENT_ACTION
	
	if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CHANNELING:
		if input_table[Constants.PlayerInput.GBA_B][I_T_JUST_RELEASED]:
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
	
	if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
		if input_table[Constants.PlayerInput.DOWN][I_T_JUST_RELEASED]:
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
			
	if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
		if input_table[Constants.PlayerInput.GBA_A][I_T_JUST_RELEASED]:
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
	
	# process MOVING_STATUS
	
	if not player.actions[Constants.ActionType.MOVE] and not player.actions[Constants.ActionType.DASH]:
		player.set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)

func set_logging_iteration(unit : Unit, delta):
	if (log_triggered or
	(num_iterations != 0
	and false)):
		time_elapsed_to_log = time_elapsed
		log_triggered = true
		print("Iteration identified: " + str(time_elapsed_to_log))
		unit.log_unit()

func terminate_logging_iteration(unit : Unit):
	if time_elapsed == time_elapsed_to_log:
		print("Iteration ended")
		num_iterations = num_iterations - 1
		unit.log_unit()
		if num_iterations == 0:
			log_triggered = false

func conditional_log(message : String):
	if is_log_condition():
		print(get_log_msg(message))

func get_log_msg(message : String):
	return str(time_elapsed) + " " + message

func is_log_condition():
	return time_elapsed == time_elapsed_to_log
