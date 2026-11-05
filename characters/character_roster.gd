class_name CharacterRoster
extends Resource
## Every playable character, in Armory order, and how many locked slots to
## show for characters still to come.

@export var characters: Array[CharacterData] = []
## Unlocked from the start (others are unlocked by meta progression later).
@export var starting_unlocks: Array[StringName] = [&"knight"]
## Empty "???" places shown in the Armory for characters not made yet.
@export var placeholder_slots: int = 3


func find(id: StringName) -> CharacterData:
	for character: CharacterData in characters:
		if character.id == id:
			return character
	return null
