class_name CrystalSkinEffect
extends CardEffect
## 7♥: each health crystal grants armour until the end of the level.

@export var armour_per_crystal: float = 6.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _bonus: StatModifier
	var _crystals: int = 0

	func on_equip() -> void:
		listen(player.events.crystal_used, _on_crystal)
		listen(player.events.level_started, _on_level_started)

	func _on_crystal() -> void:
		_crystals += 1
		_apply()

	func _on_level_started() -> void:
		_crystals = 0
		_apply()

	func _apply() -> void:
		var per: float = (data as CrystalSkinEffect).armour_per_crystal
		_bonus = set_modifier(_bonus, StatIds.ARMOUR, StatModifier.Type.FLAT, per * _crystals)
