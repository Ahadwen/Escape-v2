class_name SpawnEntry
extends Resource
## One enemy type the ThreatDirector may spawn, and when.

@export var enemy: EnemyData
## Relative chance among the entries currently allowed.
@export var weight: float = 1.0
## Not spawned until threat reaches this.
@export var min_threat: float = 0.0


func cost() -> float:
	return enemy.threat_cost if enemy != null else 0.0
