class_name StatBuffExecution
extends AbilityExecution

var _data: StatBuffAbilityData
var _modifier: StatModifier
var _remaining: float = 0.0


func _init(p_context: CastContext, data: StatBuffAbilityData) -> void:
	super(p_context)
	_data = data


func start() -> void:
	if context.stats == null:
		finished = true
		return
	var amount: float = (
		_data.amount_scaling.evaluate(context.stats) if _data.amount_scaling != null else 0.0
	)
	_modifier = StatModifier.new(
		_data.stat, _data.modifier_type, amount, StringName("ability:%s" % _data.id)
	)
	context.stats.add_modifier(_modifier)
	_remaining = _data.duration


func physics_tick(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		_end()


func cancel() -> void:
	_end()


func _end() -> void:
	if _modifier != null and context.stats != null:
		context.stats.remove_modifier(_modifier)
		_modifier = null
	finished = true
