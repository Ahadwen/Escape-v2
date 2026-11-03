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

# Aces. PC: keys 1-4 use ace stack 1-4 (in slot order).
const USE_ACE_1: StringName = &"use_ace_1"
const USE_ACE_2: StringName = &"use_ace_2"
const USE_ACE_3: StringName = &"use_ace_3"
const USE_ACE_4: StringName = &"use_ace_4"
# Gamepad: D-pad left/right cycles the selected ace, B/Circle uses it.
const ACE_PREVIOUS: StringName = &"ace_previous"
const ACE_NEXT: StringName = &"ace_next"
const USE_SELECTED_ACE: StringName = &"use_selected_ace"
const ACE_KEY_COUNT: int = 4
const USE_ACE_KEYS: Array[StringName] = [USE_ACE_1, USE_ACE_2, USE_ACE_3, USE_ACE_4]

# Debug builds only: cycle PC -> gamepad -> touch scheme (disables auto-detect).
const DEBUG_CYCLE_SCHEME: StringName = &"debug_cycle_input_scheme"
# Debug builds only: spawn the next enemy type near the player.
const DEBUG_SPAWN_ENEMY: StringName = &"debug_spawn_enemy"
# Debug builds only: get a chest's worth of loot.
const DEBUG_GIVE_LOOT: StringName = &"debug_give_loot"
# Debug builds only: pick any card to receive.
const DEBUG_CARD_PICKER: StringName = &"debug_card_picker"
# Debug builds only: skip to the next level (keeps cards and gold).
const DEBUG_NEXT_LEVEL: StringName = &"debug_next_level"

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
	USE_ACE_1,
	USE_ACE_2,
	USE_ACE_3,
	USE_ACE_4,
	ACE_PREVIOUS,
	ACE_NEXT,
	USE_SELECTED_ACE,
	DEBUG_CYCLE_SCHEME,
	DEBUG_SPAWN_ENEMY,
	DEBUG_GIVE_LOOT,
	DEBUG_CARD_PICKER,
	DEBUG_NEXT_LEVEL,
]


## Returns the action for a zero-based ability slot index.
static func ability(slot: int) -> StringName:
	assert(slot >= 0 and slot < ABILITY_SLOT_COUNT, "Ability slot out of range: %d" % slot)
	return ABILITIES[slot]
