class_name ThickOfItEffect
extends CardEffect
## J♠: move speed and armour for each enemy close by (capped).

const REFRESH: float = 0.25

@export var radius: float = 4.0
@export var max_enemies: int = 5
@export var speed_per_enemy: float = 0.3
@export var armour_per_enemy: float = 5.0


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _timer: float = 0.0
	var _speed: StatModifier
	var _armour: StatModifier

	func physics_tick(delta: float) -> void:
		_timer -= delta
		if _timer > 0.0:
			return
		_timer = ThickOfItEffect.REFRESH
		var effect: ThickOfItEffect = data as ThickOfItEffect
		var count: int = (
			AreaEffects
			. enemies_in_radius(player.get_tree(), player.global_position, effect.radius)
			. size()
		)
		count = mini(count, effect.max_enemies)
		_speed = set_modifier(
			_speed, StatIds.MOVE_SPEED, StatModifier.Type.FLAT, effect.speed_per_enemy * count
		)
		_armour = set_modifier(
			_armour, StatIds.ARMOUR, StatModifier.Type.FLAT, effect.armour_per_enemy * count
		)
