class_name SecondWindEffect
extends CardEffect
## 10♥: once per level, a lethal hit leaves you at 1 HP, briefly invulnerable.

@export var invulnerability: float = 1.5


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _used: bool = false

	func on_equip() -> void:
		intercept_damage(_intercept)
		listen(player.events.level_started, func() -> void: _used = false)

	func _intercept(_event: DamageEvent, amount: float) -> float:
		var current: float = player.health.pool.current
		if _used or amount < current:
			return amount
		_used = true
		var grace: float = (data as SecondWindEffect).invulnerability
		player.status.apply(InvulnerableEffect.new(grace, &"second_wind"))
		return current - 1.0
