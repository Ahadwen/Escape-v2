class_name OathboundEffect
extends CardEffect
## J♣: your ultimate is disabled, but you gain a large % of Will.

@export var will_percent: float = 0.6


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _disabled: Array[AbilitySlot] = []

	func on_equip() -> void:
		add_modifier(
			StatIds.WILL, StatModifier.Type.PERCENT_ADD, (data as OathboundEffect).will_percent
		)
		for ability_slot: AbilitySlot in player.abilities.slots:
			if ability_slot.data != null and ability_slot.data.has_tag(AbilityData.TAG_ULTIMATE):
				ability_slot.disabled = true
				_disabled.append(ability_slot)

	func on_unequip() -> void:
		for ability_slot: AbilitySlot in _disabled:
			ability_slot.disabled = false
		_disabled.clear()
