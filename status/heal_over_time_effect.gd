class_name HealOverTimeEffect
extends StatusEffect
## Heals a total amount evenly over the duration.

var total: float
var _rate: float


func _init(p_total: float, p_duration: float, p_id: StringName = &"heal_over_time") -> void:
	super(p_id, p_duration)
	total = p_total
	_rate = p_total / maxf(p_duration, 0.001)
	ticks_with_host = true


func tick_host(host: StatusEffectHost, delta: float) -> void:
	if host.health != null:
		host.health.heal(_rate * minf(delta, maxf(remaining, 0.0)))
