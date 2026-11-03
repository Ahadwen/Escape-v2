class_name PercentStatEffect
extends CardEffect
## A percent bonus to one stat while held (card stats themselves are flat).

@export var stat: StringName = StatIds.WILL
## 0.4 = +40%.
@export var percent: float = 0.4


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	func on_equip() -> void:
		var effect: PercentStatEffect = data as PercentStatEffect
		add_modifier(effect.stat, StatModifier.Type.PERCENT_ADD, effect.percent)
