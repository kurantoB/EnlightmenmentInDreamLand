extends Node

class_name GameScene

export var tile_set_name: String
export(Array, String) var tilemaps_to_scale
export(Array, String) var tilemaps_to_parallax_scroll

const Constants = preload("res://Scripts/Constants.gd")

export(Array, float) var parallax_scroll_factors = []
export(float) var player_move_speed : float = Constants.UNIT_TYPE_MOVE_SPEEDS[Constants.UnitType.PLAYER]
export(float) var dash_speed : float = Constants.DASH_SPEED
export(float) var player_jump_speed : float = Constants.UNIT_TYPE_JUMP_SPEEDS[Constants.UnitType.PLAYER]
export(float) var player_jump_duration : float = Constants.CURRENT_ACTION_TIMERS[Constants.UnitType.PLAYER][Constants.UnitCurrentAction.JUMPING]
export(float) var player_float_speed : float = Constants.FLOAT_SPEED
export(float) var player_float_cooldown : float = Constants.ACTION_TIMERS[Constants.UnitType.PLAYER][Constants.ActionType.FLOAT]
export(float) var player_dash_window : float = Constants.ACTION_TIMERS[Constants.UnitType.PLAYER][Constants.ActionType.DASH]
export(float) var player_slide_duration : float = Constants.CURRENT_ACTION_TIMERS[Constants.UnitType.PLAYER][Constants.UnitCurrentAction.SLIDING]
export(float) var player_recoil_duration : float = Constants.CURRENT_ACTION_TIMERS[Constants.UnitType.PLAYER][Constants.UnitCurrentAction.RECOILING]
export(float) var player_invincible_duration : float = Constants.UNIT_CONDITION_TIMERS[Constants.UnitType.PLAYER][Constants.UnitCondition.IS_INVINCIBLE][0]
export(float) var move_acceleration : float = Constants.ACCELERATION
export(float) var gravity : float = Constants.GRAVITY
export(float) var gravity_lite : float = Constants.GRAVITY_LITE
export(float) var max_fall_speed : float = Constants.MAX_FALL_SPEED
export(float) var max_fall_speed_lite : float = Constants.MAX_FALL_LITE

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
	if parallax_scroll_factors.size() != tilemaps_to_parallax_scroll.size():
		printerr("Parallax scroll factor array does not align with tilemaps to parallax scroll array.")
		get_tree().quit()
	
	units.append(get_node("Player"))
	player = units[0]
	player.init_unit_w_scene(self)
	stage_env = load("res://Scripts/StageEnvironment.gd").new(self)
	player_cam = player.get_node("Camera2D")
	player_cam.make_current()
	get_node("AudioStreamPlayer").play()
	
	for tilemap_to_scale in tilemaps_to_scale:
		if has_node(tilemap_to_scale):
			var this_tilemap_to_scale = get_node(tilemap_to_scale)
			this_tilemap_to_scale.scale.x = Constants.SCALE_FACTOR
			this_tilemap_to_scale.scale.y = Constants.SCALE_FACTOR
		else:
			printerr("Unable to find tilemap to scale: " + tilemap_to_scale)
			get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for unit in units:
		unit.reset_actions()
	handle_player_input()
	# handle enemy input
	for unit in units:
		unit.process_unit(delta, time_elapsed, self)
		set_logging_iteration(unit, delta)
		stage_env.interact(unit, delta)
		unit.react(delta)
		stage_env.interact_post(unit)
		terminate_logging_iteration(unit)
		time_elapsed = time_elapsed + delta
	
	# visual effects
	if (player.facing == Constants.Direction.RIGHT):
		player_cam.offset_h = 1
	else:
		player_cam.offset_h = -1
	for i in range(tilemaps_to_parallax_scroll.size()):
		if has_node(tilemaps_to_parallax_scroll[i]):
			var this_tilemap_to_parallax_scroll = get_node(tilemaps_to_parallax_scroll[i])
			this_tilemap_to_parallax_scroll.position.x = player_cam.get_camera_screen_center().x - player_cam.get_camera_screen_center().x * parallax_scroll_factors[i]
			this_tilemap_to_parallax_scroll.position.y = player_cam.get_camera_screen_center().y - player_cam.get_camera_screen_center().y * parallax_scroll_factors[i]
		else:
			printerr("Unable to find tilemap to parallax scroll: " + tilemaps_to_parallax_scroll[i])
			get_tree().quit()

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
	
	if (player.get_current_action() == Constants.UnitCurrentAction.RECOILING
	or player.get_current_action() == Constants.UnitCurrentAction.SLIDING):
		return
	
	# process input_table

	if input_table[Constants.PlayerInput.UP][I_T_PRESSED]:
		if player.get_current_action() == Constants.UnitCurrentAction.IDLE:
			player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
			player.set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)
		elif player.get_current_action() == Constants.UnitCurrentAction.FLYING or player.get_current_action() == Constants.UnitCurrentAction.FLYING_CEILING:
			player.do_with_timeout(Constants.ActionType.FLOAT, -1)
	
	if input_table[Constants.PlayerInput.DOWN][I_T_PRESSED]:
		if ((player.get_current_action() == Constants.UnitCurrentAction.IDLE and player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND])
		or player.get_current_action() == Constants.UnitCurrentAction.CROUCHING):
			player.set_action(Constants.ActionType.CROUCH)
	
	if ((input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] or input_table[Constants.PlayerInput.RIGHT][I_T_PRESSED])
	and player.get_current_action() != Constants.UnitCurrentAction.CHANNELING and player.get_current_action() != Constants.UnitCurrentAction.CROUCHING):
		if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] and input_table[Constants.PlayerInput.RIGHT][I_T_PRESSED]:
			input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] = false
			input_table[Constants.PlayerInput.LEFT][I_T_JUST_PRESSED] = false
		var input_dir
		if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED]:
			input_dir = Constants.Direction.LEFT
		else:
			input_dir = Constants.Direction.RIGHT
		if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
				if player.timer_actions[Constants.ActionType.DASH] > 0 and player.dash_facing == input_dir:
					player.set_action(Constants.ActionType.DASH)
				else:
					player.set_action(Constants.ActionType.MOVE)
			elif player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.MOVING:
				player.set_action(Constants.ActionType.MOVE)
			else:
				if player.facing == input_dir:
					player.set_action(Constants.ActionType.DASH)
				else:
					player.set_action(Constants.ActionType.MOVE)
			player.dash_facing = input_dir
			player.set_timer_action(Constants.ActionType.DASH)
		else:
			if (player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.DASHING
			and input_dir == player.facing
			and player.h_speed != 0):
				player.set_action(Constants.ActionType.DASH)
			else:
				player.set_action(Constants.ActionType.MOVE)
				player.reset_timer_action(Constants.ActionType.DASH)
		# set facing
		player.facing = input_dir				
	
	if input_table[Constants.PlayerInput.GBA_A][I_T_PRESSED]:
		if player.get_current_action() == Constants.UnitCurrentAction.CROUCHING and input_table[Constants.PlayerInput.GBA_A][I_T_JUST_PRESSED]:
			player.set_action(Constants.ActionType.SLIDE)
		elif player.get_current_action() == Constants.UnitCurrentAction.JUMPING:
			player.set_action(Constants.ActionType.JUMP)
		elif player.get_current_action() == Constants.UnitCurrentAction.IDLE:
			if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
				if input_table[Constants.PlayerInput.GBA_A][I_T_JUST_PRESSED]:
					player.set_action(Constants.ActionType.JUMP)
			elif input_table[Constants.PlayerInput.GBA_A][I_T_JUST_PRESSED]:
				player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
		elif player.get_current_action() == Constants.UnitCurrentAction.FLYING or player.get_current_action() == Constants.UnitCurrentAction.FLYING_CEILING:
			player.do_with_timeout(Constants.ActionType.FLOAT, -1)
	
	if input_table[Constants.PlayerInput.GBA_B][I_T_PRESSED]:
		# if crouching
		if player.get_current_action() == Constants.UnitCurrentAction.CROUCHING and input_table[Constants.PlayerInput.GBA_B][I_T_JUST_PRESSED]:
			# slide
			player.set_action(Constants.ActionType.SLIDE)
		# else if flying and just pressed
		elif ((player.get_current_action() == Constants.UnitCurrentAction.FLYING or player.get_current_action() == Constants.UnitCurrentAction.FLYING_CEILING)
		and input_table[Constants.PlayerInput.GBA_B][I_T_JUST_PRESSED]):
			player.set_action(Constants.ActionType.CANCEL_FLYING)
		# else if channeling or (idle and not floating and just pressed)
		elif (player.get_current_action() == Constants.UnitCurrentAction.CHANNELING
		or ((player.get_current_action() == Constants.UnitCurrentAction.IDLE or player.get_current_action() == Constants.UnitCurrentAction.JUMPING) 
		and input_table[Constants.PlayerInput.GBA_B][I_T_JUST_PRESSED])):
			# channel
			player.set_action(Constants.ActionType.CHANNEL)
	
	if (input_table[Constants.PlayerInput.GBA_SELECT][I_T_JUST_PRESSED]
	and player.unit_conditions[Constants.UnitCondition.HAS_ABILITY]
	and player.get_current_action() != Constants.UnitCurrentAction.CHANNELING
	and player.get_current_action() != Constants.UnitCurrentAction.SLIDING):
		player.set_action(Constants.ActionType.DROP_ABILITY)
	
	# process CURRENT_ACTION
	
	if player.get_current_action() == Constants.UnitCurrentAction.CHANNELING:
		if input_table[Constants.PlayerInput.GBA_B][I_T_JUST_RELEASED]:
			player.stop_channel_sparks()
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
	
	if player.get_current_action() == Constants.UnitCurrentAction.CROUCHING:
		if input_table[Constants.PlayerInput.DOWN][I_T_JUST_RELEASED]:
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
			
	if player.get_current_action() == Constants.UnitCurrentAction.JUMPING:
		if not input_table[Constants.PlayerInput.GBA_A][I_T_PRESSED]:
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
