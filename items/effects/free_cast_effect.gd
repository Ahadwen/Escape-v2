class_name FreeCastEffect
extends CardEffect
## 10♠: once every so often, a non-ultimate ability doesn't trigger its
## cooldown.

@export var interval: float = 60.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _timer: float = 0.0

	func on_equip() -> void:
		listen(player.abilities.casting, _on_casting)

	func physics_tick(delta: float) -> void:
		_timer -= delta

	func is_ready() -> bool:
		return _timer <= 0.0

	func _on_casting(_slot: int, ability_slot: AbilitySlot) -> void:
		if _timer > 0.0 or ability_slot.data.has_tag(AbilityData.TAG_ULTIMATE):
			return
		ability_slot.next_cooldown_override = 0.0
		_timer = (data as FreeCastEffect).interval
