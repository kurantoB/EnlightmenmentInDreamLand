enum UnitType {
	PLAYER,
	JUMP_BIRD,
}

enum ActionType {
	CANCEL_FLYING,
	CHANNEL,
	CROUCH,
	JUMP,
	MOVE,
	DASH,
	DROP_ABILITY,
	FLOAT,
	RECOIL,
	SLIDE,
}

enum UnitCondition {
	CURRENT_ACTION,
	HAS_ABILITY,
	IS_ON_GROUND,
	MOVING_STATUS
	IS_INVINCIBLE,
}

enum UnitCurrentAction {
	IDLE,
	CHANNELING,
	CROUCHING,
	JUMPING,
	SLIDING,
	FLYING,
	RECOILING,
}

enum UnitMovingStatus {
	IDLE,
	MOVING,
	DASHING,
}

enum PlayerInput {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	GBA_A,
	GBA_B,
	GBA_START,
	GBA_SELECT,
}

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

enum MapElemType {
	SQUARE,
	SLOPE_LEFT,
	SLOPE_RIGHT,
	SMALL_SLOPE_LEFT_1,
	SMALL_SLOPE_LEFT_2,
	SMALL_SLOPE_RIGHT_1,
	SMALL_SLOPE_RIGHT_2,
	LEDGE,
	HAZARD,
}

enum SpriteClass {
	IDLE,
	WALK,
	JUMP,
	DASH,
	FLY,
	SLIDE,
	RECOIL,
	CHANNEL,
	CROUCH,
 }

enum HIT_BOX_BOUND {
	UPPER_BOUND,
	LOWER_BOUND,
	LEFT_BOUND,
	RIGHT_BOUND
}

const UNIT_TYPE_ACTIONS = {
	UnitType.PLAYER: [
		ActionType.CANCEL_FLYING,
		ActionType.CHANNEL,
		ActionType.CROUCH,
		ActionType.JUMP,
		ActionType.MOVE,
		ActionType.DASH,
		ActionType.DROP_ABILITY,
		ActionType.FLOAT,
		ActionType.RECOIL,
		ActionType.SLIDE,
	],
	UnitType.JUMP_BIRD: [
		ActionType.JUMP,
		ActionType.MOVE,
	]
}

const UNIT_TYPE_CURRENT_ACTIONS = {
	UnitType.PLAYER: [
		UnitCurrentAction.IDLE,
		UnitCurrentAction.CHANNELING,
		UnitCurrentAction.CROUCHING,
		UnitCurrentAction.JUMPING,
		UnitCurrentAction.SLIDING,
		UnitCurrentAction.FLYING,
		UnitCurrentAction.RECOILING,
	],
	UnitType.JUMP_BIRD: [
		UnitCurrentAction.IDLE,
		UnitCurrentAction.JUMPING,
	]
}

const CURRENT_ACTION_HAS_MELEE_HITBOX = {
	UnitCurrentAction.IDLE: false,
	UnitCurrentAction.CHANNELING: false,
	UnitCurrentAction.CROUCHING: false,
	UnitCurrentAction.JUMPING: false,
	UnitCurrentAction.SLIDING: true,
	UnitCurrentAction.FLYING: false,
	UnitCurrentAction.RECOILING: false,
}

const UNIT_TYPE_HEALTH = {
	UnitType.PLAYER: 6,
	UnitType.JUMP_BIRD: 1,
}

const UNIT_TYPE_CONDITIONS = {
	UnitType.PLAYER: {
		UnitCondition.CURRENT_ACTION: UnitCurrentAction.IDLE,
		UnitCondition.HAS_ABILITY: false,
		UnitCondition.IS_ON_GROUND: false,
		UnitCondition.MOVING_STATUS: UnitMovingStatus.IDLE,
		UnitCondition.IS_INVINCIBLE: false,
	},
	UnitType.JUMP_BIRD: {
		UnitCondition.CURRENT_ACTION: UnitCurrentAction.IDLE,
		UnitCondition.IS_ON_GROUND: false,
		UnitCondition.MOVING_STATUS: UnitMovingStatus.IDLE,
	},
}

const ACTION_TIMERS = {
	UnitType.PLAYER: {
		ActionType.FLOAT: 0.25,
		ActionType.DASH: 0.25
	},
	UnitType.JUMP_BIRD: {},
}

const CURRENT_ACTION_TIMERS = {
	UnitType.PLAYER: {
		UnitCurrentAction.SLIDING: 0.7,
		UnitCurrentAction.RECOILING: 0.67,
		UnitCurrentAction.JUMPING: 0.35,
	},
	UnitType.JUMP_BIRD: {
		UnitCurrentAction.JUMPING: 0.2,
	}
}

const UNIT_CONDITION_TIMERS = {
	# condition type: [duration, on value, off value]
	UnitType.PLAYER: {
		UnitCondition.IS_INVINCIBLE: [2.5, true, false],
	},
	UnitType.JUMP_BIRD: {},
}

const ENV_COLLIDERS = {
	UnitType.PLAYER: [
		[Vector2(0, 1.5), [Direction.LEFT, Direction.UP, Direction.RIGHT]],
		[Vector2(-.33, .25), [Direction.LEFT]],
		[Vector2(.33, .25), [Direction.RIGHT]],
		[Vector2(-.33, 1.25), [Direction.LEFT]],
		[Vector2(.33, 1.25), [Direction.RIGHT]],
		[Vector2(0, 0), [Direction.LEFT, Direction.DOWN, Direction.RIGHT]],
	],
	UnitType.JUMP_BIRD: [
		[Vector2(0, 1), [Direction.LEFT, Direction.UP, Direction.RIGHT]],
		[Vector2(-.33, .5), [Direction.LEFT]],
		[Vector2(.33, .5), [Direction.RIGHT]],
		[Vector2(0, 0), [Direction.LEFT, Direction.DOWN, Direction.RIGHT]],
	],
}

const CROUCH_FACTOR = 0.67 # fraction of total height

# [timestamp, [x, y, width, height]]
# assuming right-facing
#const UNIT_MELEE_HIT_BOXES = {
#	UnitType.PLAYER: {
#		UnitCurrentAction.SLIDING: [
#			[0, .5, .0, .5, .5],
#		],
#	},
#}

const INPUT_MAP = {
	PlayerInput.UP: "ui_up",
	PlayerInput.DOWN: "ui_down",
	PlayerInput.LEFT: "ui_left",
	PlayerInput.RIGHT: "ui_right",
	PlayerInput.GBA_A: "gba_a",
	PlayerInput.GBA_B: "gba_b",
	PlayerInput.GBA_START: "gba_start",
	PlayerInput.GBA_SELECT: "gba_select",
}

const UNIT_SPRITES = {
	# Sprite-class: [Is-animation?, Nodes]
	UnitType.PLAYER: {
		SpriteClass.IDLE: [true, ["Idle"]],
		SpriteClass.WALK: [true, ["Walk"]],
		SpriteClass.DASH: [true, ["Dash"]],
		SpriteClass.JUMP: [false, ["Jump1", "Jump2"]],
		SpriteClass.FLY: [false, ["Fly1", "Fly2"]],
		SpriteClass.SLIDE: [false, ["Slide"]],
		SpriteClass.RECOIL: [false, ["Recoil"]],
		SpriteClass.CHANNEL: [false, ["Channel"]],
		SpriteClass.CROUCH: [false, ["Crouch"]],
	},
	UnitType.JUMP_BIRD: {
		SpriteClass.IDLE: [false, ["Idle"]],
		SpriteClass.WALK: [true, ["Walk"]],
		SpriteClass.JUMP: [false, ["Jump", "Jump"]],
	},
}

const TILE_SET_MAP_ELEMS = {
	"PalaceOfEarthSpirits_Stage": {
		MapElemType.SQUARE: [0, 1, 2, 3, 4, 5, 6, 7, 8],
		MapElemType.SLOPE_LEFT: [19, 20],
		MapElemType.SLOPE_RIGHT: [21, 22],
		MapElemType.SMALL_SLOPE_LEFT_1: [9],
		MapElemType.SMALL_SLOPE_LEFT_2: [10, 11],
		MapElemType.SMALL_SLOPE_RIGHT_1: [12],
		MapElemType.SMALL_SLOPE_RIGHT_2: [13, 14],
		MapElemType.LEDGE: [15, 16, 17, 18],
		MapElemType.HAZARD: [24, 25, 26, 27],
	},
}

# To use for determining bounce-back direction
const TILE_SET_HAZARD_REF_X = {
	"PalaceOfEarthSpirits_Stage": {
		24: -1,
		25: Direction.RIGHT,
		26: Direction.LEFT,
		27: -1,
	}
}

const UNIT_TYPE_MOVE_SPEEDS = {
	UnitType.PLAYER: 6,
	UnitType.JUMP_BIRD: 3,
}

const UNIT_TYPE_JUMP_SPEEDS = {
	UnitType.PLAYER: 8,
	UnitType.JUMP_BIRD: 12,
}
const FLOAT_SPEED = 5.5

const SCALE_FACTOR = 3.5
const GRID_SIZE = 20
const GRAVITY = 35
const MAX_FALL_SPEED = -10
const MAX_FALL_LITE = -4
const ACCELERATION = 50
const DASH_SPEED = 12
const GRAVITY_LITE = 8
const QUANTUM_DIST = 0.001
const SPAWN_DISTANCE = 4

# Cosmetics
const FLASH_CYCLE = 0.15
const DEFEATED_LIFETIME = 0.5
