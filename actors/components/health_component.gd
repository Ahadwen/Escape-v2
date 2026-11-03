class_name HealthComponent
extends Node
## An actor's HP. Max HP comes from the max_hp stat when there is one,
## otherwise from fallback_max. Damage is mitigated by armour/resist and
## ignored while invulnerable.

signal damaged(amount: float, event: DamageEvent)
## A hit was completely prevented (invulnerable, parried, blocked).
signal damage_negated(event: DamageEvent)
signal healed(amount: float)
signal died

@export var stats: StatsComponent
@export var status: StatusEffectHost
## Max HP when there's no StatsComponent (or no max_hp stat).
@export var fallback_max: float = 100.0

var pool: ResourcePool = ResourcePool.new()
var is_dead: bool = false


func _ready() -> void:
	refresh_max(true)
	if stats != null:
		stats.block.stat_changed.connect(_on_stat_changed)


## Re-reads max HP. With fill, also restores to full.
func refresh_max(fill: bool) -> void:
	var maximum: float = fallback_max
	if stats != null and stats.block.has_base(StatIds.MAX_HP):
		maximum = stats.get_value(StatIds.MAX_HP)
	pool.set_maximum(maximum, fill)
	if fill:
		is_dead = false


## Applies damage. Returns HP actually lost.
func take_damage(event: DamageEvent) -> float:
	if is_dead:
		return 0.0
	if status != null and status.is_invulnerable():
		damage_negated.emit(event)
		return 0.0
	var amount: float = DamageResolver.resolve(event, stats.block if stats != null else null)
	var lost: float = pool.drain(amount)
	if lost > 0.0:
		damaged.emit(lost, event)
	if pool.is_empty():
		is_dead = true
		died.emit()
	return lost


func heal(amount: float) -> float:
	if is_dead:
		return 0.0
	var restored: float = pool.restore(amount)
	if restored > 0.0:
		healed.emit(restored)
	return restored


func heal_fraction(fraction: float) -> float:
	return heal(pool.maximum * fraction)


func _on_stat_changed(stat: StringName) -> void:
	if stat == StatIds.MAX_HP:
		refresh_max(false)
