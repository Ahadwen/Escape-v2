class_name MomentumEffect
extends CardEffect
## 9♠: after a movement ability, a brief speed bonus.

@export var speed: float = 1.5
@export var duration: float = 2.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	func on_equip() -> void:
		listen(player.abilities.ability_active_ended, _on_active_ended)

	func _on_active_ended(_slot: int, ability: AbilityData) -> void:
		if ability == null or not ability.has_tag(AbilityData.TAG_MOVEMENT):
			return
		var effect: MomentumEffect = data as MomentumEffect
		player.status.apply(
			SpeedBoostEffect.new(effect.speed, effect.duration, &"momentum", false, false)
		)
