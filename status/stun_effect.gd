class_name StunEffect
extends StatusEffect
## The actor can't move or act. Knockbacks still move it.


func _init(p_duration: float, p_id: StringName = &"stun") -> void:
	super(p_id, p_duration)
	stuns = true
