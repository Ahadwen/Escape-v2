class_name DesperationEffect
extends CardEffect
## 9♣: the lower your HP, the higher your Will.

@export var max_will: float = 12.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _bonus: StatModifier
	var _applied: float = -1.0

	func physics_tick(_delta: float) -> void:
		var missing: float = 1.0 - player.health.pool.fraction()
		var will: float = snappedf((data as DesperationEffect).max_will * missing, 0.5)
		if not is_equal_approx(will, _applied):
			_applied = will
			_bonus = set_modifier(_bonus, StatIds.WILL, StatModifier.Type.FLAT, will)
