class_name GhostwalkEffect
extends CardEffect
## K♠: while any active speed boost runs (from abilities or Aces), walk
## through walls. When it ends inside an obstacle, dash to the nearest
## walkable spot.

## Physics layer 1 ("world" = walls; floors are on their own layer).
const WALL_LAYER_BIT: int = 1

@export var exit_dash_speed: float = 22.0
## Further than this from the navmesh counts as "inside an obstacle".
@export var stuck_distance: float = 0.35


func create_instance() -> CardEffectInstance:
	return Instance.new()


class Instance:
	extends CardEffectInstance

	var _ghosting: bool = false
	var _exit_dash: DashMovement

	func on_unequip() -> void:
		_set_ghost(false)

	func physics_tick(_delta: float) -> void:
		var boosted: bool = player.status.has_active_speed_boost()
		if boosted:
			_set_ghost(true)
			return
		if not _ghosting:
			return
		if _exit_dash != null:
			if _exit_dash.finished:
				_exit_dash = null
				_set_ghost(false)
			return
		_exit_walls()

	func _exit_walls() -> void:
		var effect: GhostwalkEffect = data as GhostwalkEffect
		var map: RID = player.get_world_3d().navigation_map
		var here: Vector3 = player.global_position
		var safe: Vector3 = NavigationServer3D.map_get_closest_point(map, here)
		var offset: Vector3 = Vector3(safe.x - here.x, 0.0, safe.z - here.z)
		if offset.length() <= effect.stuck_distance:
			_set_ghost(false)
			return
		_exit_dash = DashMovement.new(offset, offset.length(), effect.exit_dash_speed)
		player.movement.start_override(_exit_dash)

	func _set_ghost(on: bool) -> void:
		if on == _ghosting:
			return
		_ghosting = on
		if on:
			player.collision_mask &= ~GhostwalkEffect.WALL_LAYER_BIT
		else:
			player.collision_mask |= GhostwalkEffect.WALL_LAYER_BIT
