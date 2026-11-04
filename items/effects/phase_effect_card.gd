class_name PhaseCardEffect
extends CardEffect
## Q♠: when an ability's active part ends, pass through enemies and their
## projectiles briefly.

## Physics layers 3 ("enemies") and 6 ("crowd": Shamblers).
const ENEMY_LAYER_BIT: int = 4 | 32

@export var duration: float = 1.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _removed_bit: bool = false

	func on_equip() -> void:
		listen(player.abilities.ability_active_ended, _on_active_ended)

	func on_unequip() -> void:
		_restore()

	func _on_active_ended(_slot: int, _ability: AbilityData) -> void:
		player.status.apply(PhaseEffect.new((data as PhaseCardEffect).duration, &"card_phase"))

	func physics_tick(_delta: float) -> void:
		if player.status.is_phased():
			if player.collision_mask & PhaseCardEffect.ENEMY_LAYER_BIT:
				player.collision_mask &= ~PhaseCardEffect.ENEMY_LAYER_BIT
				_removed_bit = true
		else:
			_restore()

	func _restore() -> void:
		if _removed_bit:
			player.collision_mask |= PhaseCardEffect.ENEMY_LAYER_BIT
			_removed_bit = false
