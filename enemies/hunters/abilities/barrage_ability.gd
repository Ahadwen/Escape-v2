class_name BarrageAbility
extends HunterAbility
## The Artillerist's barrage: one circle right where you stand, then an
## irregular scatter of circles of different sizes around you, appearing and
## detonating at uneven times. Walking on doesn't save you: find the gaps.

@export var count: int = 9
## Circles land within this distance of you.
@export var spread: float = 7.5
@export var radius_min: float = 1.6
@export var radius_max: float = 2.8
## Circles keep at least this much space between their edges (gaps exist).
@export var min_gap: float = 0.6
## Time from a circle appearing to it detonating (random in this range).
@export var fuse_min: float = 0.9
@export var fuse_max: float = 1.4
## Delay between circles appearing (random in this range).
@export var stagger_min: float = 0.05
@export var stagger_max: float = 0.25
@export var damage: float = 45.0
@export var cast_time: float = 0.3
@export var recovery: float = 0.4
@export var color: Color = Color(1.0, 0.5, 0.2)


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


## Circles (x, z = centre, y = radius): the first on `center`, the rest
## scattered irregularly within `spread`, not overlapping (best effort).
func scatter(center: Vector3, rng: RandomNumberGenerator) -> Array[Vector3]:
	var circles: Array[Vector3] = [Vector3(center.x, radius_min, center.z)]
	var attempts: int = 0
	while circles.size() < count and attempts < count * 30:
		attempts += 1
		var angle: float = rng.randf() * TAU
		var distance: float = sqrt(rng.randf()) * spread
		var r: float = rng.randf_range(radius_min, radius_max)
		var candidate: Vector3 = Vector3(
			center.x + cos(angle) * distance, r, center.z + sin(angle) * distance
		)
		if _fits(candidate, circles):
			circles.append(candidate)
	return circles


func _fits(candidate: Vector3, circles: Array[Vector3]) -> bool:
	for other: Vector3 in circles:
		var apart: float = Vector2(candidate.x - other.x, candidate.z - other.z).length()
		if apart < candidate.y + other.y + min_gap:
			return false
	return true


class Action:
	extends HunterAction

	var ability: BarrageAbility
	var _timer: float = 0.0
	var _placed: int = 0
	var _circles: Array[Vector3] = []
	var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

	func _init(p_brain: HunterBrain, p_ability: BarrageAbility) -> void:
		super(p_brain)
		ability = p_ability
		_rng.randomize()

	func start() -> void:
		enemy().movement.stop()
		enemy().set_tell(true)
		_timer = ability.cast_time
		var center: Vector3 = enemy().global_position
		if brain.target != null:
			center = brain.target.world_position()
		_circles = ability.scatter(center, _rng)

	func tick(delta: float) -> bool:
		_timer -= delta
		if _timer > 0.0:
			return false
		if _placed < _circles.size():
			enemy().set_tell(false)
			_place(_circles[_placed])
			_placed += 1
			if _placed < _circles.size():
				_timer = _rng.randf_range(ability.stagger_min, ability.stagger_max)
			else:
				_timer = ability.recovery
			return false
		return true

	func cancel() -> void:
		enemy().set_tell(false)

	func _place(circle: Vector3) -> void:
		var strike: GroundStrike = GroundStrike.new()
		strike.color = ability.color
		strike.configure(
			Vector3(circle.x, 0.0, circle.z),
			circle.y,
			_rng.randf_range(ability.fuse_min, ability.fuse_max),
			enemy().scaled_damage(ability.damage),
			enemy().data.damage_type,
			enemy()
		)
		spawn_in_world(strike)
