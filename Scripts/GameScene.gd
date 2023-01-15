extends Node

class_name GameScene

export var tile_set_name: String
export(Array, String) var tilemaps_to_scale
export(Array, String) var tilemaps_to_parallax_scroll

# positions to unit string
export var spawning : Dictionary

const Constants = preload("res://Scripts/Constants.gd")

export(Array, float) var parallax_scroll_factors = []

const Unit = preload("res://Scripts/Unit.gd")
const UNIT_DIRECTORY = {
	Constants.UnitType.JUMP_BIRD: preload("res://Units/JumpBird.tscn"),
}

var units = []
var inactive_units = []
var spawning_map = {} # keeps track of what's alive
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

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	if parallax_scroll_factors.size() != tilemaps_to_parallax_scroll.size():
		printerr("Parallax scroll factor array does not align with tilemaps to parallax scroll array.")
		get_tree().quit()
	
	units.append(get_node("Player"))
	player = units[0]
	player.init_unit_w_scene(self)
	player_cam = player.get_node("Camera2D")
	player_cam.make_current()
	
	# place the units
	stage_env = load("res://Scripts/StageEnvironment.gd").new(self)
	
	get_node("AudioStreamPlayer").play()
	
	for tilemap_to_scale in tilemaps_to_scale:
		if has_node(tilemap_to_scale):
			var this_tilemap_to_scale = get_node(tilemap_to_scale)
			this_tilemap_to_scale.scale.x = Constants.SCALE_FACTOR
			this_tilemap_to_scale.scale.y = Constants.SCALE_FACTOR
		else:
			printerr("Unable to find tilemap to scale: " + tilemap_to_scale)
			get_tree().quit()
	
	for spawning_key in spawning:
		spawning_map[spawning_key] = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_spawning()
	
	for unit in units:
		unit.reset_actions()
		unit.handle_input(delta)
		unit.process_unit(delta, time_elapsed, self)
		set_logging_iteration(unit, delta)
		stage_env.interact(unit, delta) # also check enviroment hazard hits
		unit.react(delta)
		stage_env.interact_post(unit)
		unit.death_check()
		terminate_logging_iteration(unit)
	for unit in inactive_units:
		# defeated units are still affected by the environment
		unit.process_unit(delta, time_elapsed, self)
		stage_env.interact(unit, delta)
		unit.react(delta)
		stage_env.interact_post(unit)
		unit.death_cleanup()
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
	
	if player.get_current_action() == Constants.UnitCurrentAction.RECOILING:
		player.set_action(Constants.ActionType.RECOIL)
		return
	if player.get_current_action() == Constants.UnitCurrentAction.SLIDING:
		player.set_action(Constants.ActionType.SLIDE)
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
		elif (player.get_current_action() == Constants.UnitCurrentAction.FLYING
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

func reset_player_current_action():
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

func process_spawning():
	for one_spawn in spawning.keys():
		if spawning_map[one_spawn] != null:
			continue
		if abs(one_spawn[0] - player.pos.x) >= 10 or abs(one_spawn[1] - player.pos.y) >= 10:
			continue
		if abs(one_spawn[0] - player.pos.x) <= 9:
			continue
		# NPCUnit
		var enemy_scene = UNIT_DIRECTORY[Constants.UnitType.get(spawning[one_spawn])]
		var enemy_instance = enemy_scene.instance()
		add_child(enemy_instance)
		units.append(enemy_instance)
		enemy_instance.spawn_point = one_spawn
		spawning_map[one_spawn] = enemy_instance
		enemy_instance.pos.x = one_spawn[0]
		enemy_instance.pos.y = one_spawn[1]
		enemy_instance.position.x = enemy_instance.pos.x * Constants.GRID_SIZE
		enemy_instance.position.y = -1 * enemy_instance.pos.y * Constants.GRID_SIZE
		enemy_instance.init_unit_w_scene(self)

func set_logging_iteration(unit : Unit, delta):
	if (log_triggered or
	(num_iterations != 0
	# and unit.unit_type == Constants.UnitType.PLAYER and unit.pos.x < 14.25 and time_elapsed > 5)):
	and false)):
		time_elapsed_to_log = time_elapsed
		log_triggered = true
		unit.log_unit()

func terminate_logging_iteration(unit : Unit):
	if time_elapsed == time_elapsed_to_log:
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
