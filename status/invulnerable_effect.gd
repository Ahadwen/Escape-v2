class_name InvulnerableEffect
extends StatusEffect
## The actor takes no damage.


func _init(p_duration: float, p_id: StringName = &"invulnerable") -> void:
	super(p_id, p_duration)
	invulnerable = true
