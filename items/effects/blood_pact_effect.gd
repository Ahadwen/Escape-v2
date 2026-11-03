class_name BloodPactEffect
extends CardEffect
## Q♥: strong regen (paused for a few seconds after taking damage), but every
## ability cast costs HP. Paying HP doesn't pause the regen.

@export var regen: float = 6.0
@export var cast_cost: float = 12.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	func on_equip() -> void:
		add_modifier(StatIds.HP_REGEN, StatModifier.Type.FLAT, (data as BloodPactEffect).regen)
		listen(player.abilities.ability_cast, _on_cast)

	func _on_cast(_slot: int) -> void:
		player.health.pay_hp((data as BloodPactEffect).cast_cost)
