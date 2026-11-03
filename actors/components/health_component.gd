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

const DAMAGE_LOG_SECONDS: float = 5.0

@export var stats: StatsComponent
@export var status: StatusEffectHost
## Max HP when there's no StatsComponent (or no max_hp stat).
@export var fallback_max: float = 100.0
## Seconds without taking damage before hp_regen kicks in.
@export var regen_delay: float = 3.0

## Called in order on every hit after mitigation: func(event, amount) -> float
## returning the new amount. Returning <= 0 blocks the hit (counts as negated).
## Used by blocks, front shields and "survive a lethal hit" effects.
var interceptors: Array[Callable] = []

var pool: ResourcePool = ResourcePool.new()
var is_dead: bool = false
## Seconds since damage was last taken.
var time_since_damage: float = INF

## [time, amount] pairs for recent damage (see damage_in_last).
var _damage_log: Array[Vector2] = []
var _clock: float = 0.0


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
	for interceptor: Callable in interceptors.duplicate():
		if not interceptor.is_valid():
			continue
		amount = interceptor.call(event, amount)
		if amount <= 0.0:
			damage_negated.emit(event)
			return 0.0
	var lost: float = pool.drain(amount)
	if lost > 0.0:
		time_since_damage = 0.0
		_damage_log.append(Vector2(_clock, lost))
		damaged.emit(lost, event)
	if pool.is_empty():
		is_dead = true
		died.emit()
	return lost


## Total HP lost to damage in the last `seconds`.
func damage_in_last(seconds: float) -> float:
	var total: float = 0.0
	for entry: Vector2 in _damage_log:
		if _clock - entry.x <= seconds:
			total += entry.y
	return total


## Loses HP without counting as being hit (e.g. ability HP costs): doesn't
## reset regen delay, isn't mitigated, ignores invulnerability. Can't kill.
func pay_hp(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	return pool.drain(minf(amount, pool.current - 1.0))


func _physics_process(delta: float) -> void:
	_clock += delta
	time_since_damage += delta
	while not _damage_log.is_empty() and _clock - _damage_log[0].x > DAMAGE_LOG_SECONDS:
		_damage_log.pop_front()
	if is_dead or stats == null:
		return
	var regen: float = stats.get_value(StatIds.HP_REGEN)
	if regen > 0.0 and time_since_damage >= regen_delay:
		pool.restore(regen * delta)


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
	if stat != StatIds.MAX_HP:
		return
	# Gaining max HP also grants that much current HP (losing it just clamps).
	var before: float = pool.maximum
	refresh_max(false)
	if pool.maximum > before and not is_dead:
		pool.restore(pool.maximum - before)
