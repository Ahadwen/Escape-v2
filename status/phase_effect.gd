class_name PhaseEffect
extends StatusEffect
## Pass through enemies and their projectiles (Q♠ Phase). The owner of the
## effect handles collision; projectiles check `phased` on their target.


func _init(p_duration: float, p_id: StringName = &"phase") -> void:
	super(p_id, p_duration)
	phased = true
