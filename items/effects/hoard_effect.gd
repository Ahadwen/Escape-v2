class_name HoardEffect
extends CardEffect
## 9♦: armour for gold held (capped).

@export var gold_per_armour: float = 25.0
@export var max_armour: float = 20.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _bonus: StatModifier

	func on_equip() -> void:
		listen(player.wallet.changed, _on_gold)
		_on_gold(player.wallet.gold)

	func _on_gold(gold: int) -> void:
		var effect: HoardEffect = data as HoardEffect
		var armour: float = minf(floorf(gold / effect.gold_per_armour), effect.max_armour)
		_bonus = set_modifier(_bonus, StatIds.ARMOUR, StatModifier.Type.FLAT, armour)
