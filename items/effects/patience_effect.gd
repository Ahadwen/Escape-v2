class_name PatienceEffect
extends CardEffect
## 7♣: every so often, your next ability cast has double Will.

@export var interval: float = 60.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _timer: float = 0.0
	var _boost: StatModifier

	func on_equip() -> void:
		listen(player.abilities.casting, _on_casting)

	func is_ready() -> bool:
		return _timer <= 0.0

	func physics_tick(delta: float) -> void:
		# Abilities read Will when cast, so the boost only needs one frame.
		_boost = set_modifier(_boost, StatIds.WILL, StatModifier.Type.PERCENT_MULT, 0.0)
		_timer -= delta

	func _on_casting(_slot: int, _ability_slot: AbilitySlot) -> void:
		if _timer > 0.0:
			return
		_timer = (data as PatienceEffect).interval
		_boost = set_modifier(_boost, StatIds.WILL, StatModifier.Type.PERCENT_MULT, 1.0)
