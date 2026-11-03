class_name PerfectTimingEffect
extends CardEffect
## 8♠: casting an ability within a moment of it coming off cooldown gives a
## short speed burst (doesn't count for K♠ Ghostwalk).

@export var window: float = 0.3
@export var speed: float = 2.0
@export var duration: float = 1.5


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	func on_equip() -> void:
		listen(player.abilities.casting, _on_casting)

	func _on_casting(_slot: int, ability_slot: AbilitySlot) -> void:
		var effect: PerfectTimingEffect = data as PerfectTimingEffect
		if ability_slot.time_since_ready <= effect.window:
			player.status.apply(
				SpeedBoostEffect.new(effect.speed, effect.duration, &"perfect_timing", false, false)
			)
