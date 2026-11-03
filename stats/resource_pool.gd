class_name ResourcePool
extends RefCounted
## A current/max value that can be drained and restored: HP, and later mana,
## rage and other character resources.

signal changed(current: float, maximum: float)
signal depleted

var current: float = 0.0
var maximum: float = 0.0
## Units restored per second by tick().
var regen_per_second: float = 0.0


## Sets the maximum. With fill, current becomes the new maximum; otherwise
## current keeps its value, clamped to the new maximum.
func set_maximum(value: float, fill: bool = false) -> void:
	maximum = maxf(value, 0.0)
	current = maximum if fill else minf(current, maximum)
	changed.emit(current, maximum)


## Removes up to amount. Returns how much was actually removed.
func drain(amount: float) -> float:
	if amount <= 0.0 or current <= 0.0:
		return 0.0
	var drained: float = minf(amount, current)
	current -= drained
	changed.emit(current, maximum)
	if current <= 0.0:
		depleted.emit()
	return drained


## Adds up to amount (capped at maximum). Returns how much was actually added.
func restore(amount: float) -> float:
	if amount <= 0.0 or current >= maximum:
		return 0.0
	var restored: float = minf(amount, maximum - current)
	current += restored
	changed.emit(current, maximum)
	return restored


func fraction() -> float:
	return current / maximum if maximum > 0.0 else 0.0


func is_empty() -> bool:
	return current <= 0.0


func tick(delta: float) -> void:
	if regen_per_second > 0.0 and current > 0.0:
		restore(regen_per_second * delta)
