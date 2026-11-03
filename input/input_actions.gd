class_name InputActions
extends RefCounted
## The single list of abstract input actions used by the game.
##
## Gameplay and input schemes refer to actions only through these constants,
## never through string literals. Device bindings for each action live in the
## InputMap (Project Settings > Input Map) and can be remapped at runtime.

# PC: right-click to move to a point on the ground.
const MOVE_TO: StringName = &"move_to"
# PC: confirm an aimed cast (left click).
const CONFIRM: StringName = &"confirm"
# PC: stop moving in place.
const STOP: StringName = &"stop"

# Gamepad left stick: movement direction.
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const MOVE_UP: StringName = &"move_up"
const MOVE_DOWN: StringName = &"move_down"

# Gamepad right stick: aim direction.
const AIM_LEFT: StringName = &"aim_left"
const AIM_RIGHT: StringName = &"aim_right"
const AIM_UP: StringName = &"aim_up"
const AIM_DOWN: StringName = &"aim_down"

# Ability slots 1-4. What each slot does comes from the chosen character.
const ABILITY_1: StringName = &"ability_1"
const ABILITY_2: StringName = &"ability_2"
const ABILITY_3: StringName = &"ability_3"
const ABILITY_4: StringName = &"ability_4"

const INTERACT: StringName = &"interact"
const PAUSE: StringName = &"pause"

# Debug builds only: cycle PC -> gamepad -> touch scheme (disables auto-detect).
const DEBUG_CYCLE_SCHEME: StringName = &"debug_cycle_input_scheme"
# Debug builds only: spawn the next enemy type near the player.
const DEBUG_SPAWN_ENEMY: StringName = &"debug_spawn_enemy"

const ABILITY_SLOT_COUNT: int = 4

const ABILITIES: Array[StringName] = [ABILITY_1, ABILITY_2, ABILITY_3, ABILITY_4]

const ALL: Array[StringName] = [
	MOVE_TO,
	CONFIRM,
	STOP,
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	AIM_LEFT,
	AIM_RIGHT,
	AIM_UP,
	AIM_DOWN,
	ABILITY_1,
	ABILITY_2,
	ABILITY_3,
	ABILITY_4,
	INTERACT,
	PAUSE,
	DEBUG_CYCLE_SCHEME,
	DEBUG_SPAWN_ENEMY,
]


## Returns the action for a zero-based ability slot index.
static func ability(slot: int) -> StringName:
	assert(slot >= 0 and slot < ABILITY_SLOT_COUNT, "Ability slot out of range: %d" % slot)
	return ABILITIES[slot]
