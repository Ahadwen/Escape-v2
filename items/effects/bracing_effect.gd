class_name BracingEffect
extends CardEffect
## 8♥: taking a hit grants armour briefly (internal cooldown).

@export var armour: float = 15.0
@export var duration: float = 2.0
@export var cooldown: float = 8.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _cooldown: float = 0.0

	func on_equip() -> void:
		listen(player.health.damaged, _on_damaged)

	func physics_tick(delta: float) -> void:
		_cooldown -= delta

	func _on_damaged(_amount: float, _event: DamageEvent) -> void:
		if _cooldown > 0.0:
			return
		var effect: BracingEffect = data as BracingEffect
		_cooldown = effect.cooldown
		add_timed_modifier(StatIds.ARMOUR, StatModifier.Type.FLAT, effect.armour, effect.duration)
