class_name StatScaling
extends Resource
## Maps a stat to an ability parameter: value = base_value + per_point * stat.
## Abilities declare scalings as data, so tuning never touches behaviour code.

@export var stat: StringName = StatIds.WILL
@export var base_value: float = 0.0
@export var per_point: float = 0.0


func evaluate(stats: StatBlock) -> float:
	if stats == null:
		return base_value
	return base_value + per_point * stats.get_value(stat)
