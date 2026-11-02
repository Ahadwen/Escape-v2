class_name CharacterData
extends Resource
## A playable character: base stats and the four abilities it brings.

@export var id: StringName
@export var display_name: String

@export_group("Base stats")
@export var max_hp: float = 400.0
@export var move_speed: float = 5.0
@export var will: float = 10.0
@export var armour: float = 0.0
@export var elemental_resist: float = 0.0
## Any further stats (e.g. character-specific ones), keyed by stat name.
@export var extra_stats: Dictionary[StringName, float] = {}

@export_group("Abilities")
@export var ability_1: AbilityData
@export var ability_2: AbilityData
@export var ability_3: AbilityData
@export var ability_4: AbilityData


func get_base_stats() -> Dictionary[StringName, float]:
	var stats: Dictionary[StringName, float] = {
		StatIds.MAX_HP: max_hp,
		StatIds.MOVE_SPEED: move_speed,
		StatIds.WILL: will,
		StatIds.ARMOUR: armour,
		StatIds.ELEMENTAL_RESIST: elemental_resist,
	}
	stats.merge(extra_stats, true)
	return stats


func get_abilities() -> Array[AbilityData]:
	return [ability_1, ability_2, ability_3, ability_4]
