class_name AimPreviewPresenter
extends Node
## Turns aim previews from the input router into an on-ground indicator,
## using the ability in the previewed slot to decide shape and length.

## Length of the generic aim line (slot -1, or a slot with no range).
const GENERIC_AIM_LENGTH: float = 3.0
const POINT_MARKER_RADIUS: float = 0.8

@export var abilities: AbilityCaster
@export var movement: ActorMovement
@export var indicator: AimIndicator


func show_preview(slot: int, aim: AimData) -> void:
	var origin: Vector3 = abilities.caster.global_position
	var direction: Vector3 = aim.direction if not aim.is_none() else movement.get_facing()
	var ability: AbilityData = abilities.get_ability(slot)
	if ability == null:
		indicator.show_direction(origin, direction, GENERIC_AIM_LENGTH)
		return
	var ability_range: float = ability.get_range(abilities.stats.block)
	match ability.targeting:
		AbilityData.Targeting.DIRECTION:
			var length: float = ability_range if ability_range > 0.0 else GENERIC_AIM_LENGTH
			indicator.show_direction(origin, direction, length)
		AbilityData.Targeting.POINT:
			var strength: float = aim.strength if not aim.is_none() else 1.0
			indicator.show_point(origin + direction * ability_range * strength, POINT_MARKER_RADIUS)
		_:
			indicator.clear()


func clear_preview() -> void:
	indicator.clear()
