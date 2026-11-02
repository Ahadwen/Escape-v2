class_name StatBlock
extends RefCounted
## Base stat values plus modifiers. Nothing writes final stat values directly:
## items, buffs and upgrades add and remove modifiers.

signal stat_changed(stat: StringName)

var _base: Dictionary[StringName, float] = {}
var _modifiers: Array[StatModifier] = []
var _cache: Dictionary[StringName, float] = {}


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	_invalidate(stat)


func has_base(stat: StringName) -> bool:
	return _base.has(stat)


func get_base(stat: StringName) -> float:
	return _base.get(stat, 0.0)


func get_value(stat: StringName) -> float:
	if not _cache.has(stat):
		_cache[stat] = _compute(stat)
	return _cache[stat]


func add_modifier(modifier: StatModifier) -> void:
	_modifiers.append(modifier)
	_invalidate(modifier.stat)


func remove_modifier(modifier: StatModifier) -> void:
	var index: int = _modifiers.find(modifier)
	if index == -1:
		return
	_modifiers.remove_at(index)
	_invalidate(modifier.stat)


func remove_modifiers_from(source: StringName) -> void:
	var removed_stats: Array[StringName] = []
	for i: int in range(_modifiers.size() - 1, -1, -1):
		var modifier: StatModifier = _modifiers[i]
		if modifier.source == source:
			_modifiers.remove_at(i)
			if not removed_stats.has(modifier.stat):
				removed_stats.append(modifier.stat)
	for stat: StringName in removed_stats:
		_invalidate(stat)


func _compute(stat: StringName) -> float:
	var flat: float = 0.0
	var percent_add: float = 0.0
	var multiplier: float = 1.0
	for modifier: StatModifier in _modifiers:
		if modifier.stat != stat:
			continue
		match modifier.type:
			StatModifier.Type.FLAT:
				flat += modifier.value
			StatModifier.Type.PERCENT_ADD:
				percent_add += modifier.value
			StatModifier.Type.PERCENT_MULT:
				multiplier *= 1.0 + modifier.value
	return (get_base(stat) + flat) * maxf(0.0, 1.0 + percent_add) * multiplier


func _invalidate(stat: StringName) -> void:
	_cache.erase(stat)
	stat_changed.emit(stat)
