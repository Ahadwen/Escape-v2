class_name StatsComponent
extends Node
## Gives an actor a StatBlock.

var block: StatBlock = StatBlock.new()


func initialize(base_stats: Dictionary[StringName, float]) -> void:
	for stat: StringName in base_stats:
		block.set_base(stat, base_stats[stat])


func get_value(stat: StringName) -> float:
	return block.get_value(stat)
