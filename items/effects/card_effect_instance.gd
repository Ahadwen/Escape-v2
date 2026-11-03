class_name CardEffectInstance
extends RefCounted
## Runtime half of a CardEffect, alive while its card is held. Subclasses
## override on_equip / physics_tick; helpers track modifiers, connections and
## damage interceptors so unequipping cleans everything up.

var player: Player
var data: CardEffect

var _modifiers: Array[StatModifier] = []
var _connections: Array[Array] = []
var _interceptors: Array[Callable] = []
var _source: StringName = &""
## [modifier, seconds left] for timed modifiers.
var _timed: Array[Array] = []


func equip(p_player: Player, p_data: CardEffect) -> void:
	player = p_player
	data = p_data
	_source = StringName("card_effect:%d" % get_instance_id())
	on_equip()


func unequip() -> void:
	on_unequip()
	for modifier: StatModifier in _modifiers:
		player.stats.block.remove_modifier(modifier)
	_modifiers.clear()
	for pair: Array in _connections:
		var signal_ref: Signal = pair[0]
		var callable: Callable = pair[1]
		if signal_ref.is_connected(callable):
			signal_ref.disconnect(callable)
	_connections.clear()
	for interceptor: Callable in _interceptors:
		player.health.interceptors.erase(interceptor)
	_interceptors.clear()


## Override.
func on_equip() -> void:
	pass


## Override.
func on_unequip() -> void:
	pass


## Called by the inventory every physics frame: runs timers, then physics_tick.
func tick(delta: float) -> void:
	for i: int in range(_timed.size() - 1, -1, -1):
		_timed[i][1] -= delta
		if _timed[i][1] <= 0.0:
			remove_modifier(_timed[i][0])
			_timed.remove_at(i)
	physics_tick(delta)


## Override. Called every physics frame while held.
func physics_tick(_delta: float) -> void:
	pass


## A modifier that removes itself after `seconds`.
func add_timed_modifier(
	stat: StringName, type: StatModifier.Type, value: float, seconds: float
) -> void:
	_timed.append([add_modifier(stat, type, value), seconds])


func listen(signal_ref: Signal, callable: Callable) -> void:
	signal_ref.connect(callable)
	_connections.append([signal_ref, callable])


func intercept_damage(callable: Callable) -> void:
	player.health.interceptors.append(callable)
	_interceptors.append(callable)


func add_modifier(stat: StringName, type: StatModifier.Type, value: float) -> StatModifier:
	var modifier: StatModifier = StatModifier.new(stat, type, value, _source)
	player.stats.block.add_modifier(modifier)
	_modifiers.append(modifier)
	return modifier


func remove_modifier(modifier: StatModifier) -> void:
	if modifier == null:
		return
	player.stats.block.remove_modifier(modifier)
	_modifiers.erase(modifier)


## Replaces a previously added modifier with a new value (or removes it if
## value is 0). Returns the new modifier (or null).
func set_modifier(
	previous: StatModifier, stat: StringName, type: StatModifier.Type, value: float
) -> StatModifier:
	remove_modifier(previous)
	if is_zero_approx(value):
		return null
	return add_modifier(stat, type, value)
