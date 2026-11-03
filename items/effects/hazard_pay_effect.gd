class_name HazardPayEffect
extends CardEffect
## 10♦: every minute survived pays gold, scaling with threat.

@export var interval: float = 60.0
@export var gold_per_threat: float = 5.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _timer: float = 0.0

	func on_equip() -> void:
		_timer = (data as HazardPayEffect).interval

	func physics_tick(delta: float) -> void:
		_timer -= delta
		if _timer > 0.0:
			return
		var effect: HazardPayEffect = data as HazardPayEffect
		_timer = effect.interval
		var director: ThreatDirector = ThreatDirector.find(player.get_tree())
		var threat: float = director.threat if director != null else 1.0
		player.wallet.add(roundi(effect.gold_per_threat * threat))
