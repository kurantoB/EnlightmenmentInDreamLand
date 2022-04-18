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

const UNIT_TYPE_MOVING_STATUS = {
	UnitType.PLAYER: [
		UnitMovingStatus.IDLE,
		UnitMovingStatus.MOVING,
		UnitMovingStatus.DASHING
	],
}

const UNIT_TYPE_CONDITIONS = {
	UnitType.PLAYER: {
		UnitCondition.CURRENT_ACTION: UNIT_TYPE_CURRENT_ACTIONS[UnitType.PLAYER][UnitCurrentAction.IDLE],
		UnitCondition.HAS_ABILITY: false,
		UnitCondition.IS_ON_GROUND: false,
		UnitCondition.IS_PORTING: false,
		UnitCondition.MOVING_STATUS: UNIT_TYPE_MOVING_STATUS[UnitType.PLAYER][UnitMovingStatus.IDLE],
		UnitCondition.IS_INVINCIBLE: false,
		UnitCondition.IS_GRAVITY_AFFECTED: true,
	},
}

const PLAYER_TIMERS = {
	ActionType.SLIDE: 0.5,
	ActionType.FLOAT: 0.25,
	ActionType.DASH: 0.2
}

const CURRENT_ACTION_TIMERS = {
	UnitType.PLAYER: {
		UnitCurrentAction.SLIDING: 1.5,
		UnitCurrentAction.RECOILING: 1.5,
		UnitCurrentAction.JUMPING: 0.5,
	}
}

const UNIT_CONDITION_TIMERS = {
	UnitType.PLAYER: {
		UnitCondition.IS_INVINCIBLE: 3.0
	}
}

enum DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

const ENV_COLLIDERS = {
	UnitType.PLAYER: [
		[Vector2(0, 1.5), [DIRECTION.LEFT, DIRECTION.UP, DIRECTION.RIGHT]],
		[Vector2(0, .75), [DIRECTION.LEFT, DIRECTION.RIGHT]],
		[Vector2(0, 0), [DIRECTION.LEFT, DIRECTION.DOWN, DIRECTION.RIGHT]],
	],
	UnitType.TEST_ENEMY: [
		[0, 20, [DIRECTION.LEFT, DIRECTION.UP, DIRECTION.RIGHT]],
		[0, 10, [DIRECTION.LEFT, DIRECTION.RIGHT]],
		[0, 0, [DIRECTION.LEFT, DIRECTION.DOWN, DIRECTION.RIGHT]],
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

const UNIT_TYPE_MOVE_SPEEDS = {
	UnitType.PLAYER: 1
}

const UNIT_TYPE_JUMP_SPEEDS = {
	UnitType.PLAYER: 3
}

enum MAP_ELEM_TYPES {
	SQUARE,
	SLOPE_LEFT,
	SLOPE_RIGHT,
	SMALL_SLOPE_LEFT_1,
	SMALL_SLOPE_LEFT_2,
	SMALL_SLOPE_RIGHT_1,
	SMALL_SLOPE_RIGHT_2,
	LEDGE,
}

const SCALE_FACTOR = 3
const GRID_SIZE = 20
const GRAVITY = 12
const MAX_FALL_SPEED = -8
const ACCELERATION = 20
const MOVE_SPEED = 5
const DASH_SPEED = 9
const GRAVITY_LITE = 0.1
const QUANTUM_DIST = 0.001
