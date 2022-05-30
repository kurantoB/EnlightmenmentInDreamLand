extends Unit

class_name Player

var jump_available : bool = true
var float_available : bool = true
var dash_facing : int
var just_absorbed : bool = false

# Called when the node enters the scene tree for the first time
func _ready():
	for timer_action_num in Constants.UNIT_TIMERS[Constants.UnitType.PLAYER].keys():
		timer_actions[timer_action_num] = 0

func handle_input_move():
	actions[Constants.ActionType.MOVE] = true
	unit_conditions[Constants.UnitCondition.MOVING_STATUS] = Constants.UnitMovingStatus.MOVING
	target_move_speed = Constants.MOVE_SPEEDS[Constants.UnitType.PLAYER]

func handle_input_dash():
	actions[Constants.ActionType.DASH] = true
	unit_conditions[Constants.UnitCondition.MOVING_STATUS] = Constants.UnitMovingStatus.DASHING
	target_move_speed = Constants.DASH_SPEED

func reset_actions():
	.reset_actions()
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING:
		actions[Constants.ActionType.SLIDE] = true
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.RECOILING:
		actions[Constants.ActionType.RECOIL] = true

func execute_actions(delta, scene):
	for action_num in actions.keys():
		if !actions[action_num]:
			continue
		var found_action = true
		match action_num:
			Constants.ActionType.CANCEL_FLYING:
				cancel_flying()
			Constants.ActionType.CROUCH:
				crouch()
			Constants.ActionType.DASH:
				dash(delta)
			Constants.ActionType.DIGEST:
				digest()
			Constants.ActionType.DISCARD:
				discard()
			Constants.ActionType.DROP_PORTING:
				drop_porting()
			Constants.ActionType.FLOAT:
				flot()
			Constants.ActionType.RECOIL:
				recoil()
			Constants.ActionType.SLIDE:
				slide()
			_:
				found_action = false
		if found_action:
			actions[action_num] = false
	.execute_actions(delta, scene)

func cancel_flying():
	pass

func crouch():
	pass

func digest():
	pass

func discard():
	pass

func dash(delta):
	#if (unit_conditions[Constants.UnitCondition.MOVING_STATUS] != Constants.UnitMovingStatus.IDLE
	#and unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE
	#and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]):
	set_sprite("Dash")

func drop_porting():
	pass

func flot():
	v_speed = Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type] * .67

func recoil():
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.RECOILING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.RECOILING:
		unit_conditions[Constants.UnitCondition.IS_INVINCIBLE] = true
		unit_condition_timers[Constants.UnitCondition.IS_INVINCIBLE] = Constants.UNIT_CONDITION_TIMERS[unit_type][Constants.UnitCondition.IS_INVINCIBLE]
		set_current_action(Constants.UnitCurrentAction.RECOILING)

func slide():
	var dir_factor = 1
	if facing == Constants.DIRECTION.LEFT:
		dir_factor = -1
	h_speed = Constants.DASH_SPEED * dir_factor
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.SLIDING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)
