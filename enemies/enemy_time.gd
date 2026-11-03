class_name EnemyTime
extends RefCounted
## A shared time scale for everything enemies do: their decisions, movement,
## projectiles and ground attacks. Used by effects like A♠ Slow Time.
## Enemy lifetimes are NOT scaled (slowing them must never keep enemies
## around longer... or shorter).

static var _slow_scale: float = 1.0
static var _remaining: float = 0.0


static func scale() -> float:
	return _slow_scale if _remaining > 0.0 else 1.0


## Slows enemies to `time_scale` (0.7 = 30% slower) for `seconds`. A
## stronger or longer slow replaces a weaker one.
static func slow(time_scale: float, seconds: float) -> void:
	if _remaining <= 0.0 or time_scale <= _slow_scale:
		_slow_scale = clampf(time_scale, 0.05, 1.0)
	_remaining = maxf(_remaining, seconds)


static func tick(delta: float) -> void:
	if _remaining > 0.0:
		_remaining -= delta


static func reset() -> void:
	_slow_scale = 1.0
	_remaining = 0.0
