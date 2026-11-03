class_name AlchemyEffect
extends CardEffect
## 8♣: using an Ace grants Will for a while.

@export var will: float = 8.0
@export var duration: float = 10.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	func on_equip() -> void:
		listen(player.events.ace_used, _on_ace_used)

	func _on_ace_used(_card: CardData) -> void:
		var effect: AlchemyEffect = data as AlchemyEffect
		add_timed_modifier(StatIds.WILL, StatModifier.Type.FLAT, effect.will, effect.duration)
