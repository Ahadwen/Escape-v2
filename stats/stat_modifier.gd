class_name StatModifier
extends RefCounted
## A change to one stat from one source (item, buff, meta upgrade).
##
## Final value = (base + sum FLAT) * (1 + sum PERCENT_ADD) * product(1 + PERCENT_MULT)

enum Type { FLAT, PERCENT_ADD, PERCENT_MULT }

var stat: StringName
var type: Type
var value: float
## Who added it, so everything from one source can be removed together.
var source: StringName


func _init(p_stat: StringName, p_type: Type, p_value: float, p_source: StringName = &"") -> void:
	stat = p_stat
	type = p_type
	value = p_value
	source = p_source
