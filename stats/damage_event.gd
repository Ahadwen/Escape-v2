class_name DamageEvent
extends RefCounted
## One instance of incoming damage, before mitigation.

enum DamageType { PHYSICAL, ELEMENTAL }

var amount: float
var type: DamageType
## Who dealt it (an enemy, a hazard). May be null.
var source: Node


func _init(
	p_amount: float, p_type: DamageType = DamageType.PHYSICAL, p_source: Node = null
) -> void:
	amount = p_amount
	type = p_type
	source = p_source
