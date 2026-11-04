class_name BarrageAbility
extends HunterAbility
## The Artillerist's barrage: marks a cluster of circles around where you're
## heading; they detonate one after another. Find the gaps.

@export var count: int = 5
@export var radius: float = 2.2
@export var spread: float = 4.5
## Time from a circle appearing to it detonating.
@export var fuse: float = 1.0
## Delay between circles appearing.
@export var stagger: float = 0.2
@export var damage: float = 45.0
@export var cast_time: float = 0.3
@export var recovery: float = 0.4
@export var color: Color = Color(1.0, 0.5, 0.2)


func create_action(brain: HunterBrain) -> HunterAction:
	return Action.new(brain, self)


class Action:
	extends HunterAction

	var ability: BarrageAbility
	var _timer: float = 0.0
	var _placed: int = 0
	var _points: Array[Vector3] = []

	func _init(p_brain: HunterBrain, p_ability: BarrageAbility) -> void:
		super(p_brain)
		ability = p_ability

	func start() -> void:
		enemy().movement.stop()
		enemy().set_tell(true)
		_timer = ability.cast_time
		var center: Vector3 = enemy().global_position
		if brain.target != null:
			center = brain.target.predicted_position(ability.fuse * 0.6)
		_points = BarrageAbility.cluster(center, ability.count, ability.spread, randf() * TAU)

	func tick(delta: float) -> bool:
		_timer -= delta
		if _timer > 0.0:
			return false
		if _placed < _points.size():
			enemy().set_tell(false)
			_place(_points[_placed])
			_placed += 1
			_timer = ability.stagger if _placed < _points.size() else ability.recovery
			return false
		return true

	func cancel() -> void:
		enemy().set_tell(false)

	func _place(point: Vector3) -> void:
		var strike: GroundStrike = GroundStrike.new()
		strike.color = ability.color
		strike.configure(
			point,
			ability.radius,
			ability.fuse,
			enemy().scaled_damage(ability.damage),
			enemy().data.damage_type,
			enemy()
		)
		spawn_in_world(strike)


## One circle on the centre, the rest in a ring around it (shuffled order).
static func cluster(center: Vector3, count: int, spread: float, turn: float) -> Array[Vector3]:
	var points: Array[Vector3] = [Vector3(center.x, 0.0, center.z)]
	for i: int in count - 1:
		var angle: float = turn + TAU * i / maxf(count - 1, 1)
		points.append(points[0] + Vector3(cos(angle), 0.0, sin(angle)) * spread)
	points.shuffle()
	return points
