class_name ObstacleKind
extends Resource
## One kind of obstacle in a zone's kit. Greybox: a coloured box. (Art pass:
## swap in a scene per kind; generation doesn't change.)

@export var kind: StringName = &"pillar"
@export var size: Vector3 = Vector3(2, 2, 2)
## Relative chance within its kit.
@export var weight: float = 1.0
@export var can_rotate: bool = false
@export var color: Color = Color(0.58, 0.58, 0.62)
