class_name FlightResponseEffect
extends CardEffect
## 7♠: dropping to low HP gives a big speed burst (long cooldown). It's an
## active speed boost (counts for K♠ Ghostwalk).

@export_range(0.0, 1.0) var hp_threshold: float = 0.3
@export var speed: float = 3.0
@export var duration: float = 3.0
@export var cooldown: float = 45.0


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
		var effect: FlightResponseEffect = data as FlightResponseEffect
		if _cooldown > 0.0 or player.health.pool.fraction() > effect.hp_threshold:
			return
		_cooldown = effect.cooldown
		player.status.apply(
			SpeedBoostEffect.new(effect.speed, effect.duration, &"flight_response", false, true)
		)
