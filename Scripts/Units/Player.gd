extends Unit

class_name Player

const RECOIL_PUSHBACK = 15
const SLIDE_COLLISION_BOUNCE = 12

var dash_facing : int
var slide_collision : bool = false

onready var standing_collision = get_node("CollisionShape2D")
onready var crouching_collision = get_node("CollisionShape2DCrouch")

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

const SLIDE_HITBOX : PackedScene = preload("res://Units/AttackHitboxes/Slide.tscn")
var slide_hitbox = SLIDE_HITBOX.instance()
onready var slide_hitbox_coord = get_node("SlideAttackCoord")

func _ready():
	._ready()
	for i in range(CHANNEL_SPARK_COUNT):
		var inst : Sprite = CHANNEL_SPARK_PREFAB.instance()
		channel_sparks.append(inst)

func process_unit(delta, time_elapsed : float, scene):
	.process_unit(delta, time_elapsed, scene)
	if (get_current_action() == Constants.UnitCurrentAction.CROUCHING
	or get_current_action() == Constants.UnitCurrentAction.SLIDING
	or get_current_action() == Constants.UnitCurrentAction.FLYING):
		standing_collision.set_deferred("disabled", true)
	else:
		standing_collision.set_deferred("disabled", false)

# dir is which direction unit is taking an attack from: left / right
func hit(damage : int, dir : int):
	.hit(damage, dir)
	set_unit_condition_with_timer(Constants.UnitCondition.IS_INVINCIBLE)
	start_flash()
	set_action(Constants.ActionType.RECOIL)
	set_current_action(Constants.UnitCurrentAction.RECOILING)
	set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)
	stop_channel_sparks()

func wall_collision():
	if get_current_action() == Constants.UnitCurrentAction.SLIDING:
		slide_collision = true

func melee_attack_check():
	if melee_hit:
		if get_current_action() == Constants.UnitCurrentAction.SLIDING:
			slide_collision = true
		melee_hit = false

func handle_input(delta):
	scene.handle_player_input()

func reset_current_action():
	.reset_current_action()
	scene.reset_player_current_action()

func handle_idle():
	.handle_idle()
	if get_current_action() == Constants.UnitCurrentAction.FLYING:
		if v_speed > 0:
			set_sprite(Constants.SpriteClass.FLY, 0)
		else:
			set_sprite(Constants.SpriteClass.FLY, 1)

func is_shortened():
	return (get_current_action() == Constants.UnitCurrentAction.CROUCHING
		or get_current_action() == Constants.UnitCurrentAction.SLIDING
		or get_current_action() == Constants.UnitCurrentAction.FLYING)

func execute_actions(delta, scene):
	.execute_actions(delta, scene)
	for action_num in Constants.UNIT_TYPE_ACTIONS[Constants.UnitType.PLAYER]:
		if !actions[action_num]:
			continue
		match action_num:
			Constants.ActionType.CANCEL_FLYING:
				cancel_flying()
			Constants.ActionType.CHANNEL:
				channel()
			Constants.ActionType.CROUCH:
				crouch()
			Constants.ActionType.DASH:
				dash()
			Constants.ActionType.DROP_ABILITY:
				drop_ability()
			Constants.ActionType.FLOAT:
				flot()
			Constants.ActionType.RECOIL:
				recoil()
			Constants.ActionType.SLIDE:
				slide()

func cancel_flying():
	set_current_action(Constants.UnitCurrentAction.IDLE)

func channel():
	if (get_current_action() != Constants.UnitCurrentAction.CHANNELING):
		init_channel_sparks()
	set_current_action(Constants.UnitCurrentAction.CHANNELING)
	set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)
	handle_channel_sparks()
	set_sprite(Constants.SpriteClass.CHANNEL)

func crouch():
	set_current_action(Constants.UnitCurrentAction.CROUCHING)
	set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)
	set_sprite(Constants.SpriteClass.CROUCH)

func drop_ability():
	set_unit_condition(Constants.UnitCondition.HAS_ABILITY, false)

func dash():
	set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.DASHING)
	target_move_speed = Constants.DASH_SPEED
	if unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		set_sprite(Constants.SpriteClass.DASH)

func flot():
	v_speed = Constants.FLOAT_SPEED
	if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.DASHING:
		unit_conditions[Constants.UnitCondition.MOVING_STATUS] = Constants.UnitMovingStatus.MOVING

func recoil():
	if is_current_action_timer_done(Constants.UnitCurrentAction.RECOILING):
		set_current_action(Constants.UnitCurrentAction.IDLE)
	else:
		set_current_action(Constants.UnitCurrentAction.RECOILING)
		set_sprite(Constants.SpriteClass.RECOIL)

func slide():
	if get_current_action() != Constants.UnitCurrentAction.SLIDING:
		slide_collision = false
	set_current_action(Constants.UnitCurrentAction.SLIDING)
	var dir_factor = 1
	if facing == Constants.Direction.LEFT:
		dir_factor = -1
	h_speed = Constants.DASH_SPEED * dir_factor
	if not slide_hitbox in attack_hitbox_scenes:
		attack_hitbox_scenes.append(slide_hitbox)
		slide_hitbox_coord.add_child(slide_hitbox)
	var slide_displ = 15
	if not last_contacted_ground_collider:
		last_contacted_ground_collider = [Vector2(0, 0), Vector2(1, 0)]
	var width = last_contacted_ground_collider[1].x - last_contacted_ground_collider[0].x
	var height = last_contacted_ground_collider[1].y - last_contacted_ground_collider[0].y
	var magn = (last_contacted_ground_collider[1] - last_contacted_ground_collider[0]).length()
	if facing == Constants.Direction.RIGHT:
		slide_hitbox_coord.position.x = width / magn * slide_displ
		slide_hitbox_coord.position.y = height / magn * slide_displ * -1
	else:
		slide_hitbox_coord.position.x = width / magn * slide_displ * -1
		slide_hitbox_coord.position.y = height / magn * slide_displ
	if is_current_action_timer_done(Constants.UnitCurrentAction.SLIDING):
		set_current_action(Constants.UnitCurrentAction.IDLE)
		cancel_attack_hitboxes()
	if slide_collision:
		set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)
		set_current_action(Constants.UnitCurrentAction.IDLE)
		v_speed = SLIDE_COLLISION_BOUNCE
		if facing == Constants.Direction.RIGHT:
			h_speed = -SLIDE_COLLISION_BOUNCE
		else:
			h_speed = SLIDE_COLLISION_BOUNCE
		slide_collision = false
		set_sprite(Constants.SpriteClass.JUMP, 0)
		cancel_attack_hitboxes()
	else:
		set_sprite(Constants.SpriteClass.SLIDE)

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
		if facing == Constants.Direction.LEFT:
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
		if facing == Constants.Direction.LEFT:
			sprite.position.x *= -1
		sprite.visible = true

func stop_channel_sparks():
	for sprite in channel_sparks:
		if sprite.get_parent() == self:
			remove_child(sprite)

func _on_Player_area_entered(area: Area2D) -> void:
	if get_condition(Constants.UnitCondition.IS_INVINCIBLE, false):
		return
	if area is Unit:
		hit_from_area(area, 1)

func hit_from_area(other_area : Area2D, damage : int):
	var collision_dir : int
	if other_area.position > position:
		collision_dir = Constants.Direction.RIGHT
	else:
		collision_dir = Constants.Direction.LEFT
	hit(damage, collision_dir)


func _on_Player_body_entered(body: Node) -> void:
	if get_condition(Constants.UnitCondition.IS_INVINCIBLE, false):
		return
	hit(1, stage_hazard_hit_direction)

func invincibility_ended():
	is_flash = false
	if get_overlapping_areas().size() > 0:
		if get_overlapping_areas()[0] is Unit:
			hit_from_area(get_overlapping_areas()[0], 1)
	if get_overlapping_bodies().size() > 0:
		hit(1, stage_hazard_hit_direction)

func handle_recoil():
	if not hit_queued:
		return
	hit_queued = false
	if get_condition(Constants.UnitCondition.IS_ON_GROUND, true):
		if h_speed > 0:
			if hit_dir == Constants.Direction.LEFT:
				v_speed -= RECOIL_PUSHBACK
			else:
				v_speed += RECOIL_PUSHBACK
		elif h_speed < 0:
			if hit_dir == Constants.Direction.LEFT:
				v_speed += RECOIL_PUSHBACK
			else:
				v_speed -= RECOIL_PUSHBACK
		else:
			v_speed = -RECOIL_PUSHBACK
			if hit_dir == Constants.Direction.LEFT:
				h_speed = Constants.QUANTUM_DIST
			else:
				h_speed = -Constants.QUANTUM_DIST
		if v_speed > 0:
			h_speed *= -1
			v_speed = -v_speed
	else:
		if hit_dir == Constants.Direction.LEFT:
			h_speed += RECOIL_PUSHBACK
		else:
			h_speed -= RECOIL_PUSHBACK
	facing = hit_dir
