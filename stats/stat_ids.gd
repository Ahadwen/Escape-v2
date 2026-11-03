class_name StatIds
extends RefCounted
## Names of the core stats. Stats are keyed by StringName so new ones can be
## added (as data) without changing StatBlock.

const MAX_HP: StringName = &"max_hp"
const MOVE_SPEED: StringName = &"move_speed"
const WILL: StringName = &"will"
const ARMOUR: StringName = &"armour"
const ELEMENTAL_RESIST: StringName = &"elemental_resist"
## Cooldowns are multiplied by 100 / (100 + haste).
const ABILITY_HASTE: StringName = &"ability_haste"
## HP per second, only after a few seconds without taking damage.
const HP_REGEN: StringName = &"hp_regen"
const GOLD_PER_PICKUP: StringName = &"gold_per_pickup"
const GOLD_PER_LEVEL: StringName = &"gold_per_level"
const GOLD_PER_CRYSTAL: StringName = &"gold_per_crystal"
const RECIPE_DISCOUNT: StringName = &"recipe_discount"
const SAFEHOUSE_INTEREST: StringName = &"safehouse_interest"

## Player-facing names, for card text.
const DISPLAY_NAMES: Dictionary[StringName, String] = {
	MAX_HP: "max HP",
	MOVE_SPEED: "m/s",
	WILL: "Will",
	ARMOUR: "armour",
	ELEMENTAL_RESIST: "elemental resist",
	ABILITY_HASTE: "ability haste",
	HP_REGEN: "HP/s regen",
	GOLD_PER_PICKUP: "gold per pickup",
	GOLD_PER_LEVEL: "gold at the start of each level",
	GOLD_PER_CRYSTAL: "gold per health crystal",
	RECIPE_DISCOUNT: "gold off recipes",
	SAFEHOUSE_INTEREST: "gold interest at each safehouse",
}


## Cooldown multiplier for an amount of ability haste.
static func haste_multiplier(haste: float) -> float:
	return 100.0 / (100.0 + maxf(haste, 0.0))
