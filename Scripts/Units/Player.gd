extends Unit

class_name Player

var jump_available : bool = true
var float_available : bool = true
var dash_facing : int
var just_absorbed : bool = false

func handle_input_dash():
	set_action(Constants.ActionType.DASH)
	unit_conditions[Constants.UnitCondition.MOVING_STATUS] = Constants.UnitMovingStatus.DASHING
	target_move_speed = Constants.DASH_SPEED

func reset_actions():
	.reset_actions()
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING:
		set_action(Constants.ActionType.SLIDE)
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.RECOILING:
		set_action(Constants.ActionType.RECOIL)

func execute_actions(delta, scene):
	for action_num in Constants.UNIT_TYPE_ACTIONS[Constants.UnitType.PLAYER]:
		if !actions[action_num]:
			continue
		var found_action = true
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

func dash():
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
