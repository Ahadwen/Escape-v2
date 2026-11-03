class_name BurnEffect
extends StatusEffect
## Burning: elemental damage every tick for the duration. Burn ticks are
## flagged so they don't re-ignite. Re-applying refreshes the duration.

const ID: StringName = &"burning"

var damage: float
var tick: float
var _next_tick: float


func _init(p_duration: float, p_tick: float, p_damage: float) -> void:
	super(ID, p_duration)
	tick = maxf(p_tick, 0.05)
	damage = p_damage
	_next_tick = tick
	ticks_with_host = true


func tick_host(host: StatusEffectHost, delta: float) -> void:
	_next_tick -= delta
	if _next_tick > 0.0 or host.health == null:
		return
	_next_tick += tick
	var event: DamageEvent = DamageEvent.new(damage, DamageEvent.DamageType.ELEMENTAL, null)
	event.is_burn = true
	event.parryable = false
	host.health.take_damage(event)
