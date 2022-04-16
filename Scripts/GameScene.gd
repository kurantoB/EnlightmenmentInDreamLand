extends Node

class_name GameScene

const Constants = preload("res://Scripts/Constants.gd")
const Unit = preload("res://Scripts/Unit.gd")

var units = []
var player : Unit
var input_table = {
	Constants.PlayerInput.UP: false,
	Constants.PlayerInput.DOWN: false,
	Constants.PlayerInput.LEFT: false,
	Constants.PlayerInput.RIGHT: false,
	Constants.PlayerInput.GBA_A: false,
	Constants.PlayerInput.GBA_B: false,
	Constants.PlayerInput.GBA_SELECT: false,
}
var new_player_move_status
var stage_env


# Called when the node enters the scene tree for the first time.
func _ready():
	units.append(get_node("Player"))
	player = units[0]
	stage_env = load("res://Scripts/StageEnvironment.gd").new(self)
	player.get_node("Camera2D").make_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for unit in units:
		unit.reset_actions()
	handle_player_input()	
	# handle enemy input
	for unit in units:
		unit.process_unit(delta)
		stage_env.interact(unit, delta)
		unit.react(delta)

func handle_player_input():
	for input_num in input_table.keys():
		if Input.is_action_pressed(Constants.INPUT_MAP[input_num]):
			input_table[input_num] = true
		else:
			input_table[input_num] = false
	
	if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.RECOILING:
		return
	
	if (player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CHANNELING and !input_table[Constants.PlayerInput.GBA_B]
	or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING and !input_table[Constants.PlayerInput.DOWN]
	or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING and !input_table[Constants.PlayerInput.GBA_A] and !input_table[Constants.PlayerInput.UP]):
		player.set_current_action(Constants.UnitCurrentAction.IDLE)
		

	if input_table[Constants.PlayerInput.UP]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			if not player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
	
	if input_table[Constants.PlayerInput.DOWN]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE and player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				player.actions[Constants.ActionType.DIGEST] = true
				player.unit_conditions[Constants.UnitCondition.IS_PORTING] = false
				new_player_move_status = Constants.UnitMovingStatus.IDLE
			else:
				player.actions[Constants.ActionType.CROUCH] = true
				player.set_current_action(Constants.UnitCurrentAction.CROUCHING)
				new_player_move_status = Constants.UnitMovingStatus.IDLE
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
			player.actions[Constants.ActionType.CROUCH] = true
	
	if input_table[Constants.PlayerInput.LEFT] or input_table[Constants.PlayerInput.RIGHT]:
		if input_table[Constants.PlayerInput.LEFT] and input_table[Constants.PlayerInput.RIGHT]:
			input_table[Constants.PlayerInput.LEFT] = false
		var dir_input
		if input_table[Constants.PlayerInput.LEFT]:
			dir_input = Constants.PlayerInput.LEFT
		else:
			dir_input = Constants.PlayerInput.RIGHT
		# if action-idle
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			# if move-idle
			if player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
				# if on ground
				if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
					# if timer alive and dash-facing match
					if player.timer_actions[Constants.ActionType.DASH] > 0 and player.dash_facing == dir_input:
						# set dash
						player.actions[Constants.ActionType.DASH] = true
						new_player_move_status = Constants.UnitMovingStatus.DASHING
					# else
					else:
						# set move
						player.actions[Constants.ActionType.MOVE] = true
						new_player_move_status = Constants.UnitMovingStatus.MOVING
					# start timer, set dash-facing
					player.timer_actions[Constants.ActionType.DASH] = Constants.PLAYER_TIMERS[Constants.ActionType.DASH]
					player.dash_facing = dir_input
				# else (action-idle, move-idle, and not on ground)
				else:
					# set move
					player.actions[Constants.ActionType.MOVE] = true
					new_player_move_status = Constants.UnitMovingStatus.MOVING
			# else if move-moving
			elif player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.MOVING:
				# set move
				player.actions[Constants.ActionType.MOVE] = true
				# if on ground and facing-change
				if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] and player.facing != dir_input:
					# start timer, set dash-facing
					player.timer_actions[Constants.ActionType.DASH] = Constants.PLAYER_TIMERS[Constants.ActionType.DASH]
					player.dash_facing = dir_input
			# else (move-dashing)
			else:
				# if facing-change
				if player.facing != dir_input:
					# set move, start timer, set dash-facing
					player.actions[Constants.ActionType.MOVE] = true
					new_player_move_status = Constants.UnitMovingStatus.MOVING
					player.timer_actions[Constants.ActionType.DASH] = Constants.PLAYER_TIMERS[Constants.ActionType.DASH]
					player.dash_facing = dir_input
				# else (not facing-change)
				else:
					# set dash
					player.actions[Constants.ActionType.DASH] = true
			# set facing
			player.facing = dir_input
		# if action-jumping or action-flying
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			# set move, set facing
			player.actions[Constants.ActionType.MOVE] = true
			new_player_move_status = Constants.UnitMovingStatus.MOVING
			player.facing = dir_input
	
	if not input_table[Constants.PlayerInput.LEFT] and not input_table[Constants.PlayerInput.RIGHT]:
		new_player_move_status = Constants.UnitMovingStatus.IDLE
	
	if input_table[Constants.PlayerInput.GBA_A]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
			player.do_with_timeout(Constants.ActionType.SLIDE, Constants.UnitCurrentAction.SLIDING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
			player.actions[Constants.ActionType.JUMP] = true
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
				player.actions[Constants.ActionType.JUMP] = true
				player.set_current_action(Constants.UnitCurrentAction.JUMPING)
				player.just_jumped = true
			elif not player.unit_conditions[Constants.UnitCondition.IS_PORTING] and !player.just_jumped:
				player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)

	if !input_table[Constants.PlayerInput.GBA_A]:
		player.just_jumped = false
	
	if input_table[Constants.PlayerInput.GBA_B]:
		# if crouching
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
			# slide
			player.do_with_timeout(Constants.ActionType.SLIDE, Constants.UnitCurrentAction.SLIDING)
		# else if idle or channeling
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CHANNELING:
			# if porting and B is not still pressed after absorb
			if player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				if not player.just_absorbed:
					# drop porting
					player.actions[Constants.ActionType.DROP_PORTING] = true
					player.unit_conditions[Constants.UnitCondition.IS_PORTING] = false
			else:
				# channel
				player.actions[Constants.ActionType.CHANNEL] = true
				player.set_current_action(Constants.UnitCurrentAction.CHANNELING)
				new_player_move_status = Constants.UnitMovingStatus.IDLE
		# else if flying
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.actions[Constants.ActionType.CANCEL_FLYING] = true
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
	
	if !input_table[Constants.PlayerInput.GBA_B]:
		player.just_absorbed = false
	
	if (input_table[Constants.PlayerInput.GBA_SELECT]
	and player.unit_conditions[Constants.UnitCondition.HAS_ABILITY]
	and player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.CHANNELING
	and player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.SLIDING):
		player.actions[Constants.ActionType.DISCARD] = true
		player.unit_conditions[Constants.UnitCondition.HAS_ABILITY] = false
	
	if player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] != new_player_move_status:
		print("Setting MOVING_STATUS to " + Constants.UnitMovingStatus.keys()[new_player_move_status] + " facing " + str(player.facing))
	player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] = new_player_move_status
		
