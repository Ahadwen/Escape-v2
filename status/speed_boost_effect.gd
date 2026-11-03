class_name SpeedBoostEffect
extends StatusEffect
## Temporary move speed. Flat (m/s) or percent. `active_boost` marks boosts
## from abilities and Aces, which K♠ Ghostwalk lets you walk through walls with.

var amount: float
var percent: bool
var active_boost: bool
var _modifier: StatModifier


func _init(
	p_amount: float,
	p_duration: float,
	p_id: StringName,
	p_percent: bool = false,
	p_active_boost: bool = true
) -> void:
	super(p_id, p_duration)
	amount = p_amount
	percent = p_percent
	active_boost = p_active_boost


func on_apply(host: StatusEffectHost) -> void:
	if host.stats == null:
		return
	var type: StatModifier.Type = (
		StatModifier.Type.PERCENT_ADD if percent else StatModifier.Type.FLAT
	)
	_modifier = StatModifier.new(StatIds.MOVE_SPEED, type, amount, StringName("status:%s" % id))
	host.stats.block.add_modifier(_modifier)


func on_remove(host: StatusEffectHost) -> void:
	if _modifier != null and host.stats != null:
		host.stats.block.remove_modifier(_modifier)
		_modifier = null
