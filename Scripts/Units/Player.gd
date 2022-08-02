extends Unit

class_name Player

var dash_facing : int

func handle_input_dash():
	set_action(Constants.ActionType.DASH)
	set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.DASHING)
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
	if is_current_action_timer_done(Constants.UnitCurrentAction.RECOILING):
		set_current_action(Constants.UnitCurrentAction.IDLE)
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.RECOILING:
		set_unit_condition_with_timer(Constants.UnitCondition.IS_INVINCIBLE)
		set_current_action(Constants.UnitCurrentAction.RECOILING)

func slide():
	var dir_factor = 1
	if facing == Constants.DIRECTION.LEFT:
		dir_factor = -1
	h_speed = Constants.DASH_SPEED * dir_factor
	if is_current_action_timer_done(Constants.UnitCurrentAction.SLIDING):
		set_current_action(Constants.UnitCurrentAction.IDLE)
