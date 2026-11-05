class_name UpgradeData
extends Resource
## One Mirror upgrade: a stat bonus bought in ranks with Reagents. Applied as
## a stat modifier to the player at the start of every scene of a run.

@export var id: StringName
@export var display_name: String
## Shown in the Mirror; "%s" is replaced with the bonus at the shown rank.
@export var description: String = "%s"
@export var stat: StringName
@export var type: StatModifier.Type = StatModifier.Type.FLAT
## Bonus per rank owned.
@export var value_per_rank: float = 1.0
## Reagent cost of each rank, in order. Its size is the number of ranks.
@export var costs: PackedInt32Array = PackedInt32Array([10, 20, 35])


func max_rank() -> int:
	return costs.size()


## Cost of the next rank after `rank`, or -1 if already maxed.
func cost_after(rank: int) -> int:
	return costs[rank] if rank < costs.size() else -1


## The bonus at `rank`, as text ("+25", "+0.4").
func describe_bonus(rank: int) -> String:
	var value: float = value_per_rank * rank
	var text: String = (
		str(roundi(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
	)
	if type != StatModifier.Type.FLAT:
		text = "%d%%" % roundi(value * 100.0)
	return "+" + text


func describe(rank: int) -> String:
	return description % describe_bonus(rank)


func modifier(rank: int) -> StatModifier:
	return StatModifier.new(stat, type, value_per_rank * rank, StringName("meta:%s" % id))
