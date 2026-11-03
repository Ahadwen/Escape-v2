class_name EnemyVariant
extends Resource
## A zone's version of a shared enemy. When an enemy with id `base_id`
## spawns in this zone, it may be replaced by `variant` (chance = intensity).

@export var base_id: StringName
@export var variant: EnemyData
