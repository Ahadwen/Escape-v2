class_name VitalBloomEffect
extends CardEffect
## 9♥: health crystals heal extra HP.

@export var extra_heal: float = 50.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	func on_equip() -> void:
		listen(player.events.crystal_used, _on_crystal)

	func _on_crystal() -> void:
		player.health.heal((data as VitalBloomEffect).extra_heal)
