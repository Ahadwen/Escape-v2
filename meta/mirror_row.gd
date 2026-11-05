class_name MirrorRow
extends Resource
## A Mirror row: two alternatives; you bring one of them, or neither.

@export var id: StringName
@export var display_name: String
@export var option_a: MirrorOption
@export var option_b: MirrorOption


func option(option_id: StringName) -> MirrorOption:
	if option_a != null and option_a.id == option_id:
		return option_a
	if option_b != null and option_b.id == option_id:
		return option_b
	return null
