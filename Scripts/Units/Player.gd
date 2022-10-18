extends Unit

class_name Player

const RECOIL_PUSHBACK = 15
const SLIDE_COLLISION_BOUNCE = 12

var dash_facing : int
var slide_collision : bool = false

var channel_sparks = []
var channel_spark_spawn_times = []
var channel_spark_ys = []
const CHANNEL_SPARK_PREFAB : PackedScene = preload("res://FX/ChannelSpark.tscn")
const CHANNEL_SPARK_COUNT = 7
const CHANNEL_RANGE_PIXELS = 38
const CHANNEL_VERT_RANGE = 25
const CHANNEL_SPARK_LIFE : float = .33
var rng = RandomNumberGenerator.new()
const CHANNEL_Y_MIDPOINT = 20

func _ready():
	._ready()
	for i in range(CHANNEL_SPARK_COUNT):
		var inst : Sprite = CHANNEL_SPARK_PREFAB.instance()
		channel_sparks.append(inst)

func reset_actions():
	.reset_actions()
	if get_current_action() == scene.Constants.UnitCurrentAction.RECOILING:
		set_action(scene.Constants.ActionType.RECOIL)
	if get_current_action() == scene.Constants.UnitCurrentAction.SLIDING:
		set_action(scene.Constants.ActionType.SLIDE)

# dir is which direction unit is taking an attack from: left / right
func hit(damage : int, dir : int):
	set_action(scene.Constants.ActionType.RECOIL)
	set_current_action(scene.Constants.UnitCurrentAction.RECOILING)
	set_unit_condition(scene.Constants.UnitCondition.MOVING_STATUS, scene.Constants.UnitMovingStatus.IDLE)
	stop_channel_sparks()
	set_unit_condition_with_timer(scene.Constants.UnitCondition.IS_INVINCIBLE)
	is_flash = true
	if get_condition(scene.Constants.UnitCondition.IS_ON_GROUND, false):
		facing = dir
		var temp_h_speed
		if h_speed > 0:
			if dir == scene.Constants.Direction.LEFT:
				v_speed -= RECOIL_PUSHBACK
			else:
				v_speed += RECOIL_PUSHBACK
				if v_speed > 0:
					h_speed = -scene.Constants.QUANTUM_DIST
					v_speed *= -1
		else:
			if dir == scene.Constants.Direction.LEFT:
				v_speed += RECOIL_PUSHBACK
				if v_speed > 0:
					h_speed = scene.Constants.QUANTUM_DIST
					v_speed *= -1
			else:
				v_speed -= RECOIL_PUSHBACK
	else:
		if dir == scene.Constants.Direction.LEFT:
			h_speed += RECOIL_PUSHBACK
		else:
			h_speed -= RECOIL_PUSHBACK
	facing = dir

func wall_collision():
	if get_current_action() == scene.Constants.UnitCurrentAction.SLIDING:
		slide_collision = true

func advance_timers(delta):
	.advance_timers(delta)
	if not unit_conditions[scene.Constants.UnitCondition.IS_INVINCIBLE]:
		is_flash = false

func is_current_action_timer_done(current_action : int):
	if current_action == scene.Constants.UnitCurrentAction.SLIDING:
		return current_action_time_elapsed >= scene.player_slide_duration
	elif current_action == scene.Constants.UnitCurrentAction.RECOILING:
		return current_action_time_elapsed >= scene.player_recoil_duration
	elif current_action == scene.Constants.UnitCurrentAction.JUMPING:
		return current_action_time_elapsed >= scene.player_jump_duration
	else:
		return .is_current_action_timer_done(current_action)

func handle_unit_input(delta):
	scene.handle_player_input()

func handle_idle():
	.handle_idle()
	if get_current_action() == scene.Constants.UnitCurrentAction.FLYING or get_current_action() == scene.Constants.UnitCurrentAction.FLYING_CEILING:
		if v_speed > 0:
			set_sprite("Fly", 0)
		else:
			set_sprite("Fly", 1)
	if get_current_action() == scene.Constants.UnitCurrentAction.FLYING_CEILING and is_current_action_timer_done(scene.Constants.UnitCurrentAction.FLYING_CEILING):
		set_current_action(scene.Constants.UnitCurrentAction.FLYING)

func execute_actions(delta, scene):
	.execute_actions(delta, scene)
	for action_num in scene.Constants.UNIT_TYPE_ACTIONS[scene.Constants.UnitType.PLAYER]:
		if !actions[action_num]:
			continue
		match action_num:
			scene.Constants.ActionType.CANCEL_FLYING:
				cancel_flying()
			scene.Constants.ActionType.CHANNEL:
				channel()
			scene.Constants.ActionType.CROUCH:
				crouch()
			scene.Constants.ActionType.DASH:
				dash()
			scene.Constants.ActionType.DROP_ABILITY:
				drop_ability()
			scene.Constants.ActionType.FLOAT:
				flot()
			scene.Constants.ActionType.RECOIL:
				recoil()
			scene.Constants.ActionType.SLIDE:
				slide()

func cancel_flying():
	set_current_action(scene.Constants.UnitCurrentAction.IDLE)

func channel():
	if (get_current_action() != scene.Constants.UnitCurrentAction.CHANNELING):
		init_channel_sparks()
	set_current_action(scene.Constants.UnitCurrentAction.CHANNELING)
	set_unit_condition(scene.Constants.UnitCondition.MOVING_STATUS, scene.Constants.UnitMovingStatus.IDLE)
	handle_channel_sparks()
	set_sprite("Channel")

func crouch():
	set_current_action(scene.Constants.UnitCurrentAction.CROUCHING)
	set_unit_condition(scene.Constants.UnitCondition.MOVING_STATUS, scene.Constants.UnitMovingStatus.IDLE)
	set_sprite("Crouch")

func drop_ability():
	set_unit_condition(scene.Constants.UnitCondition.HAS_ABILITY, false)

func dash():
	set_unit_condition(scene.Constants.UnitCondition.MOVING_STATUS, scene.Constants.UnitMovingStatus.DASHING)
	target_move_speed = scene.dash_speed
	if unit_conditions[scene.Constants.UnitCondition.IS_ON_GROUND]:
		set_sprite("Dash")

func flot():
	v_speed = scene.player_float_speed
	if unit_conditions[scene.Constants.UnitCondition.MOVING_STATUS] == scene.Constants.UnitMovingStatus.DASHING:
		unit_conditions[scene.Constants.UnitCondition.MOVING_STATUS] = scene.Constants.UnitMovingStatus.MOVING

func recoil():
	if is_current_action_timer_done(scene.Constants.UnitCurrentAction.RECOILING):
		set_current_action(scene.Constants.UnitCurrentAction.IDLE)
		flash_start_timestamp = time_elapsed
	set_sprite("Recoil")

func slide():
	set_current_action(scene.Constants.UnitCurrentAction.SLIDING)
	var dir_factor = 1
	if facing == scene.Constants.Direction.LEFT:
		dir_factor = -1
	h_speed = scene.dash_speed * dir_factor
	if is_current_action_timer_done(scene.Constants.UnitCurrentAction.SLIDING):
		set_current_action(scene.Constants.UnitCurrentAction.IDLE)
	if (slide_collision):
		set_unit_condition(scene.Constants.UnitCondition.IS_ON_GROUND, false)
		set_current_action(scene.Constants.UnitCurrentAction.IDLE)
		v_speed = SLIDE_COLLISION_BOUNCE
		if facing == scene.Constants.Direction.RIGHT:
			h_speed = -SLIDE_COLLISION_BOUNCE
		else:
			h_speed = SLIDE_COLLISION_BOUNCE
		slide_collision = false
		set_sprite("Jump", 0)
	else:
		set_sprite("Slide")

func init_channel_sparks():
	channel_spark_spawn_times.clear()
	channel_spark_ys.clear()
	for i in range(channel_sparks.size()):
		var sprite : Sprite = channel_sparks[i]
		add_child(sprite)
		sprite.position.x = CHANNEL_RANGE_PIXELS + 1
		sprite.position.y = rng.randi_range(-CHANNEL_Y_MIDPOINT - CHANNEL_VERT_RANGE, -CHANNEL_Y_MIDPOINT + CHANNEL_VERT_RANGE)
		channel_spark_ys.append(sprite.position.y)
		channel_spark_spawn_times.append(time_elapsed + (i * CHANNEL_SPARK_LIFE / channel_sparks.size()))
		sprite.visible = false
		if facing == scene.Constants.Direction.LEFT:
			sprite.position.x *= -1

func handle_channel_sparks():
	for i in range(channel_sparks.size()):
		var sprite : Sprite = channel_sparks[i]
		if abs(sprite.position.x) == CHANNEL_RANGE_PIXELS + 1:
			if time_elapsed > channel_spark_spawn_times[i]:
				sprite.position.x = abs(sprite.position.x) - 1
				channel_spark_spawn_times[i] = time_elapsed
			continue
		var spark_time_elapsed = time_elapsed - channel_spark_spawn_times[i]
		if spark_time_elapsed < CHANNEL_SPARK_LIFE * 0.5:
			sprite.position.x = round(CHANNEL_RANGE_PIXELS - spark_time_elapsed / (CHANNEL_SPARK_LIFE * 0.5) * CHANNEL_RANGE_PIXELS * 0.2)
		elif spark_time_elapsed < CHANNEL_SPARK_LIFE * 0.8:
			sprite.position.x = round(CHANNEL_RANGE_PIXELS - CHANNEL_RANGE_PIXELS * 0.2 - (spark_time_elapsed - CHANNEL_SPARK_LIFE * 0.5) / (CHANNEL_SPARK_LIFE * 0.8) * CHANNEL_RANGE_PIXELS * 0.8)
		elif spark_time_elapsed < CHANNEL_SPARK_LIFE * 0.9:
			sprite.position.x = round(CHANNEL_RANGE_PIXELS - CHANNEL_RANGE_PIXELS * 0.5 - (spark_time_elapsed - CHANNEL_SPARK_LIFE * 0.8) / (CHANNEL_SPARK_LIFE * 0.9) * CHANNEL_RANGE_PIXELS * 0.9)
		elif spark_time_elapsed < CHANNEL_SPARK_LIFE * 0.95:
			sprite.position.x = round(CHANNEL_RANGE_PIXELS - CHANNEL_RANGE_PIXELS * 0.6 - (spark_time_elapsed - CHANNEL_SPARK_LIFE * 0.9) / (CHANNEL_SPARK_LIFE * 0.95) * CHANNEL_RANGE_PIXELS * 0.95)
		elif spark_time_elapsed < CHANNEL_SPARK_LIFE:
			sprite.position.x = round(CHANNEL_RANGE_PIXELS * .325)
		else:
			sprite.position.x = CHANNEL_RANGE_PIXELS
			sprite.position.y = channel_spark_ys[i]
			channel_spark_spawn_times[i] = time_elapsed
		if spark_time_elapsed < CHANNEL_SPARK_LIFE:
			sprite.position.y = round(-CHANNEL_Y_MIDPOINT + ((1 - spark_time_elapsed / CHANNEL_SPARK_LIFE) * (channel_spark_ys[i] - -CHANNEL_Y_MIDPOINT)))
		if facing == scene.Constants.Direction.LEFT:
			sprite.position.x *= -1
		sprite.visible = true

func stop_channel_sparks():
	for sprite in channel_sparks:
		remove_child(sprite)
