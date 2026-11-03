class_name DilationEffect
extends CardEffect
## 10♣: near you, enemy projectiles fly slower and ranged enemies take longer
## to wind up. Melee is unaffected.

@export var radius: float = 5.0
## 0.6 = projectiles fly 40% slower.
@export var projectile_scale: float = 0.6
## 1.3 = wind-ups take 30% longer.
@export var wind_up_scale: float = 1.3


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _field: DilationField.Field

	func on_equip() -> void:
		var effect: DilationEffect = data as DilationEffect
		_field = DilationField.add(
			player, effect.radius, effect.projectile_scale, effect.wind_up_scale
		)

	func on_unequip() -> void:
		DilationField.remove(_field)
