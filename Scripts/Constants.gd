enum UnitType {
	PLAYER,
	TEST_ENEMY
}

enum ActionType {
	CANCEL_FLYING,
	CHANNEL,
	CROUCH,
	JUMP,
	MOVE,
	DASH,
	DIGEST,
	DROP_PORTING,
	FLOAT,
	RECOIL,
	SLIDE,
	DISCARD,
}

enum UnitCondition {
	CURRENT_ACTION,
	HAS_ABILITY,
	IS_ON_GROUND,
	IS_PORTING,
	IS_RECOILING,
	MOVING_STATUS
	IS_INVINCIBLE,
	IS_GRAVITY_AFFECTED,
}

enum UnitCurrentAction {
	IDLE,
	CHANNELING,
	CROUCHING,
	JUMPING,
	SLIDING,
	FLYING,
	RECOILING
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

enum MapElemTypes {
	SQUARE,
	SLOPE_LEFT,
	SLOPE_RIGHT,
	SMALL_SLOPE_LEFT_1,
	SMALL_SLOPE_LEFT_2,
	SMALL_SLOPE_RIGHT_1,
	SMALL_SLOPE_RIGHT_2,
	LEDGE,
}

const UNIT_TYPE_ACTIONS = {
	UnitType.PLAYER: [
		ActionType.CANCEL_FLYING,
		ActionType.CHANNEL,
		ActionType.CROUCH,
		ActionType.JUMP,
		ActionType.MOVE,
		ActionType.DASH,
		ActionType.DIGEST,
		ActionType.DROP_PORTING,
		ActionType.FLOAT,
		ActionType.RECOIL,
		ActionType.SLIDE,
		ActionType.DISCARD,
	],
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
}

const UNIT_TYPE_CONDITIONS = {
	UnitType.PLAYER: {
		UnitCondition.CURRENT_ACTION: UnitCurrentAction.IDLE,
		UnitCondition.HAS_ABILITY: false,
		UnitCondition.IS_ON_GROUND: true,
		UnitCondition.IS_PORTING: false,
		UnitCondition.MOVING_STATUS: UnitMovingStatus.IDLE,
		UnitCondition.IS_INVINCIBLE: false,
		UnitCondition.IS_GRAVITY_AFFECTED: true,
	},
}

const ACTION_TIMERS = {
	UnitType.PLAYER: {
		ActionType.SLIDE: 0.5,
		ActionType.FLOAT: 0.25,
		ActionType.DASH: 0.25
	}
}

const CURRENT_ACTION_TIMERS = {
	UnitType.PLAYER: {
		UnitCurrentAction.SLIDING: 0.7,
		UnitCurrentAction.RECOILING: 1.5,
		UnitCurrentAction.JUMPING: 0.35,
	}
}

const UNIT_CONDITION_TIMERS = {
	# condition type: [duration, on value, off value]
	UnitType.PLAYER: {
		UnitCondition.IS_INVINCIBLE: [3.0, true, false]
	}
}

const ENV_COLLIDERS = {
	UnitType.PLAYER: [
		[Vector2(0, 1.5), [Direction.LEFT, Direction.UP, Direction.RIGHT]],
		[Vector2(0, .75), [Direction.LEFT, Direction.RIGHT]],
		[Vector2(0, 0), [Direction.LEFT, Direction.DOWN, Direction.RIGHT]],
	],
	UnitType.TEST_ENEMY: [
		[Vector2(0, 1), [Direction.LEFT, Direction.UP, Direction.RIGHT]],
		[Vector2(0, .5), [Direction.LEFT, Direction.RIGHT]],
		[Vector2(0, 0), [Direction.LEFT, Direction.DOWN, Direction.RIGHT]],
	],
}
const CROUCH_FACTOR = 0.67 # of total height

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
	# "Sprite class": [is animation?, [Node list]]
	UnitType.PLAYER: {
		"Idle": [true, ["Idle"]],
		"Walk": [true, ["Walk"]],
		"Dash": [true, ["Dash"]],
		"Jump": [false, ["Jump1", "Jump2"]],
		"Fly": [false, ["Fly1", "Fly2"]]
	}
}

const TILE_SET_MAP_ELEMS = {
	"PalaceOfEarthSpirits_Stage": {
		MapElemTypes.SQUARE: [0, 1, 2, 3, 4, 5, 6, 7, 8],
		MapElemTypes.SLOPE_LEFT: [19, 20],
		MapElemTypes.SLOPE_RIGHT: [21, 22],
		MapElemTypes.SMALL_SLOPE_LEFT_1: [9],
		MapElemTypes.SMALL_SLOPE_LEFT_2: [10, 11],
		MapElemTypes.SMALL_SLOPE_RIGHT_1: [12],
		MapElemTypes.SMALL_SLOPE_RIGHT_2: [13, 14],
		MapElemTypes.LEDGE: [15, 16, 17, 18],
	}
}

const UNIT_TYPE_MOVE_SPEEDS = {
	UnitType.PLAYER: 6
}

const UNIT_TYPE_JUMP_SPEEDS = {
	UnitType.PLAYER: 8
}

const SCALE_FACTOR = 3
const GRID_SIZE = 20
const GRAVITY = 35
const MAX_FALL_SPEED = -14
const MAX_FALL_LITE = -4
const ACCELERATION = 35
const DASH_SPEED = 12
const GRAVITY_LITE = 8
const QUANTUM_DIST = 0.001
const PARALLAX_SCROLL_FACTOR = .8
