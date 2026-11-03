class_name SlowEffect
extends StatusEffect
## Reduces move speed by a fraction (0.3 = 30% slower).

var amount: float
var _modifier: StatModifier


func _init(p_amount: float, p_duration: float, p_id: StringName = &"slow") -> void:
	super(p_id, p_duration)
	amount = clampf(p_amount, 0.0, 1.0)


func on_apply(host: StatusEffectHost) -> void:
	if host.stats == null:
		return
	_modifier = StatModifier.new(
		StatIds.MOVE_SPEED, StatModifier.Type.PERCENT_MULT, -amount, StringName("status:%s" % id)
	)
	host.stats.block.add_modifier(_modifier)


func on_remove(host: StatusEffectHost) -> void:
	if _modifier != null and host.stats != null:
		host.stats.block.remove_modifier(_modifier)
		_modifier = null
