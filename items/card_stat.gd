class_name CardStat
extends Resource
## One flat stat line on a card.

@export var stat: StringName
@export var value: float = 0.0


func describe() -> String:
	var name: String = StatIds.DISPLAY_NAMES.get(stat, String(stat))
	var amount: String = (
		("%+.1f" % value) if absf(value - roundf(value)) > 0.001 else ("%+d" % roundi(value))
	)
	if stat == StatIds.ABILITY_DURATION:
		return "+%d%% %s" % [roundi(value * 100.0), name]
	if stat == StatIds.RECIPE_DISCOUNT:
		return "−%d %s" % [roundi(value), name]
	return "%s %s" % [amount, name]
