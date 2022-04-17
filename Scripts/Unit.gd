extends Node2D

class_name Unit


const Constants = preload("res://Scripts/Constants.gd")
const GameUtils = preload("res://Scripts/GameUtils.gd")

# position
export var unit_type : int

var actions = {}
var unit_conditions = {}
var timer_actions = {}
var facing : int = Constants.PlayerInput.RIGHT
var dash_facing : int
var current_action_time_elapsed : float = 0
var just_absorbed : bool = false
var just_jumped : bool = false
var unit_condition_timers = {}

var pos : Vector2
var h_speed : float = 0
var v_speed : float = 0
var ground_speed : float = 0

# Called when the node enters the scene tree for the first time
func _ready():
	for action_num in Constants.UNIT_TYPE_ACTIONS[unit_type]:
		actions[action_num] = false
	for condition_num in Constants.UNIT_TYPE_CONDITIONS[unit_type].keys():
		unit_conditions[condition_num] = Constants.UNIT_TYPE_CONDITIONS[unit_type][condition_num]
	for condition_num in Constants.UNIT_CONDITION_TIMERS[unit_type].keys():
		unit_condition_timers[condition_num] = 0
	if unit_type == Constants.UnitType.PLAYER:
		for timer_action_num in Constants.PLAYER_TIMERS.keys():
			timer_actions[timer_action_num] = 0

func reset_actions():
	for action_num in actions.keys():
		actions[action_num] = false
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING:
		actions[Constants.ActionType.SLIDE] = true
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.RECOILING:
		actions[Constants.ActionType.RECOIL] = true

func process_unit(delta):
	if unit_type == Constants.UnitType.PLAYER:
		advance_timers(delta)
	current_action_time_elapsed += delta
	execute_actions(delta)

func advance_timers(delta):
	for timer_action_num in timer_actions.keys():
		timer_actions[timer_action_num] = max(0, timer_actions[timer_action_num] - delta)
	current_action_time_elapsed += delta
	for condition_num in unit_condition_timers.keys():
		unit_condition_timers[condition_num] = max(0, unit_condition_timers[condition_num] - delta)
		if unit_condition_timers[condition_num] == 0:
			unit_conditions[condition_num] = false

func set_current_action(current_action : int):
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != current_action:
		current_action_time_elapsed = 0
	unit_conditions[Constants.UnitCondition.CURRENT_ACTION] = current_action

func do_with_timeout(action : int, new_current_action : int = -1):
	if timer_actions[action] == 0:
		actions[action] = true
		timer_actions[action] = Constants.PLAYER_TIMERS[action]
		if new_current_action != -1:
			unit_conditions[Constants.UnitCondition.CURRENT_ACTION] = new_current_action

func execute_actions(delta):
	for action_num in actions.keys():
		if !actions[action_num]:
			continue
		match action_num:
			Constants.ActionType.CANCEL_FLYING:
				cancel_flying()
			Constants.ActionType.CROUCH:
				crouch()
			Constants.ActionType.DASH:
				dash()
			Constants.ActionType.DIGEST:
				digest()
			Constants.ActionType.DISCARD:
				discard()
			Constants.ActionType.DROP_PORTING:
				drop_porting()
			Constants.ActionType.FLOAT:
				flot()
			Constants.ActionType.JUMP:
				jump()
			Constants.ActionType.MOVE:
				move(delta)
			Constants.ActionType.RECOIL:
				recoil()
			Constants.ActionType.SLIDE:
				slide()
		actions[action_num] = false
	handle_moving_status(delta)

func cancel_flying():
	pass

func crouch():
	pass

func dash():
	pass

func digest():
	pass

func discard():
	pass

func drop_porting():
	pass
	
func flot():
	pass

func jump():
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.JUMPING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)

func move(delta):
	pass

func handle_moving_status(delta):
	# what we have: facing, current speed, move status, grounded
	# we want: to set new current speed
	# if grounded
	if unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED] and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		var current_magnitude : float = sqrt(pow(v_speed, 2) + pow(h_speed, 2))
		h_speed = 0
		# if move status is idle
		if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
			v_speed = min(0, -1 * (current_magnitude - Constants.ACCELERATION * delta))
		# if move status is not idle
		else:
			# if facing is aligned
			if h_speed <= 0 and facing == Constants.PlayerInput.LEFT or h_speed >= 0 and facing == Constants.PlayerInput.RIGHT:
				v_speed = max(-1 * Constants.MOVE_SPEED, -1 * (current_magnitude + Constants.ACCELERATION * delta))
			# if facing is not aligned
			else:
				v_speed = min(0, -1 * (current_magnitude - Constants.ACCELERATION * delta))
	# if not grounded
	else:
		var current_magnitude : float = abs(h_speed)
		# if move status is idle or facing is not aligned
		if (unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE
		or h_speed < 0 and facing == Constants.PlayerInput.RIGHT or h_speed > 0 and facing == Constants.PlayerInput.LEFT):
			current_magnitude = max(0, current_magnitude - Constants.ACCELERATION * delta)
		# if move status is not idle and facing is aligned
		else:
			current_magnitude = min(Constants.MOVE_SPEED, current_magnitude + Constants.ACCELERATION * delta)
		if h_speed > 0:
			h_speed = current_magnitude
		else:
			h_speed = -1 * current_magnitude

func recoil():
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.RECOILING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.RECOILING:
		unit_conditions[Constants.UnitCondition.IS_INVINCIBLE] = true
		unit_condition_timers[Constants.UnitCondition.IS_INVINCIBLE] = Constants.UNIT_CONDITION_TIMERS[unit_type][Constants.UnitCondition.IS_INVINCIBLE]
		set_current_action(Constants.UnitCurrentAction.RECOILING)

func slide():
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.SLIDING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)

func react(delta):
	pos.x = pos.x + h_speed * delta
	pos.y = pos.y + v_speed * delta
	position.x = pos.x * Constants.GRID_SIZE * Constants.SCALE_FACTOR
	position.y = -1 * pos.y * Constants.GRID_SIZE * Constants.SCALE_FACTOR

func log_unit():
	print("===UNIT DEBUG====")
	print("pos: " + str(pos))
	print("speeds: " + str(Vector2(h_speed, v_speed)))
	print("facing: " + Constants.PlayerInput.keys()[facing])
	print("conditions: action: " + Constants.UnitCurrentAction.keys()[unit_conditions[Constants.UnitCondition.CURRENT_ACTION]] + ", grounded: " + str(unit_conditions[Constants.UnitCondition.IS_ON_GROUND]) + ", movement: " + Constants.UnitMovingStatus.keys()[unit_conditions[Constants.UnitCondition.MOVING_STATUS]])
	print("=================")
