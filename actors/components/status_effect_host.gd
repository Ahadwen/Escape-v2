class_name StatusEffectHost
extends Node
## Holds an actor's active status effects and ticks them.

signal effect_applied(effect: StatusEffect)
signal effect_removed(effect: StatusEffect)

## Needed by effects that change stats (e.g. slows).
@export var stats: StatsComponent
## Needed by effects that heal (e.g. heal over time).
@export var health: HealthComponent

var _effects: Dictionary[StringName, StatusEffect] = {}


func apply(effect: StatusEffect) -> void:
	remove(effect.id)
	_effects[effect.id] = effect
	effect.on_apply(self)
	effect_applied.emit(effect)


func remove(id: StringName) -> void:
	if not _effects.has(id):
		return
	var effect: StatusEffect = _effects[id]
	_effects.erase(id)
	effect.on_remove(self)
	effect_removed.emit(effect)


func clear() -> void:
	for id: StringName in _effects.keys():
		remove(id)


func has_effect(id: StringName) -> bool:
	return _effects.has(id)


func is_stunned() -> bool:
	for effect: StatusEffect in _effects.values():
		if effect.stuns:
			return true
	return false


func is_invulnerable() -> bool:
	for effect: StatusEffect in _effects.values():
		if effect.invulnerable:
			return true
	return false


func tick(delta: float) -> void:
	for id: StringName in _effects.keys():
		if not _effects.has(id):
			continue
		var effect: StatusEffect = _effects[id]
		if effect.ticks_with_host:
			effect.tick_host(self, delta)
		if effect.tick(delta):
			remove(id)


func _physics_process(delta: float) -> void:
	tick(delta)
