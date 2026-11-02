class_name ActorMovement
extends Node
## Moves a CharacterBody3D either along a navigation path to a point or in a
## steered direction, and turns its visual to face where it's going.
## Shared by the player and (later) enemies.

signal arrived

enum Mode { IDLE, TO_POINT, DIRECTION }

@export var body: CharacterBody3D
@export var nav_agent: NavigationAgent3D
## Node rotated to face movement. Rotating a child keeps collision unaffected.
@export var visual: Node3D
## Metres per second. Will come from the actor's StatBlock in M3.
@export var move_speed: float = 5.0
## How quickly the visual turns toward the movement direction.
@export var turn_sharpness: float = 16.0

var mode: Mode = Mode.IDLE

var _direction: Vector3 = Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


## Yaw that makes a node's forward (-Z) face the given flat direction.
static func yaw_for_direction(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


func move_to(point: Vector3) -> void:
	nav_agent.target_position = point
	mode = Mode.TO_POINT


## Steer in a world direction (length 0..1 scales speed). A zero vector stops
## steering, but doesn't cancel a path that is being followed.
func move_in_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		if mode == Mode.DIRECTION:
			mode = Mode.IDLE
		return
	_direction = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	mode = Mode.DIRECTION


func stop() -> void:
	mode = Mode.IDLE


func _physics_process(delta: float) -> void:
	var desired: Vector3 = _desired_velocity()
	body.velocity.x = desired.x
	body.velocity.z = desired.z
	if body.is_on_floor():
		body.velocity.y = 0.0
	else:
		body.velocity.y -= _gravity * delta
	body.move_and_slide()
	_face(desired, delta)


func _desired_velocity() -> Vector3:
	match mode:
		Mode.TO_POINT:
			if nav_agent.is_navigation_finished():
				mode = Mode.IDLE
				arrived.emit()
				return Vector3.ZERO
			var to_next: Vector3 = nav_agent.get_next_path_position() - body.global_position
			to_next.y = 0.0
			if to_next.length_squared() < 0.0001:
				return Vector3.ZERO
			return to_next.normalized() * move_speed
		Mode.DIRECTION:
			return _direction * move_speed
	return Vector3.ZERO


func _face(velocity: Vector3, delta: float) -> void:
	if visual == null or Vector2(velocity.x, velocity.z).length_squared() < 0.01:
		return
	var weight: float = 1.0 - exp(-turn_sharpness * delta)
	visual.rotation.y = lerp_angle(visual.rotation.y, yaw_for_direction(velocity), weight)
