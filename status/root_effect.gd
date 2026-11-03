class_name RootEffect
extends StatusEffect
## Can't move (but can still act). Knockbacks and pulls still move you.


func _init(p_duration: float, p_id: StringName = &"root") -> void:
	super(p_id, p_duration)
	roots = true
