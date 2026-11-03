class_name StatusEffect
extends RefCounted
## A timed effect on an actor (slow, stun, invulnerability...). Applied
## through a StatusEffectHost. Re-applying an effect with the same id
## replaces it (refreshing its duration).

var id: StringName
var duration: float
var remaining: float
## While active, the actor can't move or act on its own.
var stuns: bool = false
## While active, the actor takes no damage.
var invulnerable: bool = false


func _init(p_id: StringName, p_duration: float) -> void:
	id = p_id
	duration = p_duration
	remaining = p_duration


func on_apply(_host: StatusEffectHost) -> void:
	pass


func on_remove(_host: StatusEffectHost) -> void:
	pass


## Advances time. Returns true when the effect has expired.
func tick(delta: float) -> bool:
	remaining -= delta
	return remaining <= 0.0
