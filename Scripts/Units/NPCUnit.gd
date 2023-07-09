extends Unit

class_name NPCUnit


export var tick_duration : float
var tick_timer : float = 0

export(Dictionary) var action_sequence_map # action sequence to weight, [] = do nothing
# action sequence is an array of action type and an array of timestamps
# action type is the string representation of Constants.ActionType
# example action map: {[[action1], [0]]: 1, [[action2, action3], [0, 1]]: 2}
var weight_sum : float

export var action_duration_map = {} # specific durations for given action
var current_npc_action_times_elapsed = {}
var current_npc_action_active = {}

var current_action_sequence = null
var current_action_sequence_time_elapsed : float = 0
var current_action_sequence_index : int = 0

var spawn_point : Vector2


func _ready():
	for action_sequence in action_sequence_map.keys():
		weight_sum += action_sequence_map[action_sequence]
	for action in action_duration_map:
		current_npc_action_times_elapsed[action] = 0
		current_npc_action_active[action] = false
	connect("area_entered", self, "_on_area_entered")

func _on_area_entered(area: Area2D):
	var dist = scene.player.pos.x - pos.x
	if dist > 0:
		hit(1, Constants.Direction.RIGHT)
	else:
		hit(1, Constants.Direction.LEFT)
	if area != scene.player:
		scene.player.melee_hit = true

func before_tick():
	pass

func handle_input(delta):
	if current_action_sequence != null:
		for action in current_npc_action_active:
			if current_npc_action_active[action]:
				if current_npc_action_times_elapsed[action] < action_duration_map[action]:
					set_action(Constants.ActionType.get(action))
					current_npc_action_times_elapsed[action] += delta
				else:
					current_npc_action_active[action] = false
		if (current_action_sequence_index < current_action_sequence[1].size()
		and current_action_sequence_time_elapsed >= current_action_sequence[1][current_action_sequence_index]):
			var action = current_action_sequence[0][current_action_sequence_index]
			set_action(Constants.ActionType.get(action))
			if action_duration_map.has(action):
				current_npc_action_active[action] = true
				current_npc_action_times_elapsed[action] = 0
			current_action_sequence_index += 1
		var current_action_sequence_duration : float = current_action_sequence[1][-1]
		if action_duration_map.has(current_action_sequence[0][-1]):
			current_action_sequence_duration += action_duration_map[current_action_sequence[0][-1]]
		if current_action_sequence_time_elapsed > current_action_sequence_duration:
			reset_npc_unit()
		current_action_sequence_time_elapsed += delta
	else:
		if tick_timer == 0:
			before_tick()
			var rand_num : float = scene.rng.randf() * weight_sum
			var temp_sum : float = 0
			for action_sequence in action_sequence_map.keys():
				temp_sum += action_sequence_map[action_sequence]
				if temp_sum >= rand_num:
					if action_sequence == []:
						tick_timer = tick_duration
					else:
						current_action_sequence = action_sequence
						current_action_sequence_time_elapsed = 0
						current_action_sequence_index = 0
					break
		else:
			tick_timer = max(0, tick_timer - delta)

func reset_npc_unit():
	current_action_sequence = null
	tick_timer = tick_duration
	for action in current_npc_action_active:
		current_npc_action_active[action] = false

func hit_check():
	pass

func unit_death_hook():
	scene.spawning_map[spawn_point] = null
