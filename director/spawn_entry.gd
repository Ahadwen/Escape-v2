class_name SpawnEntry
extends Resource
## One enemy type the ThreatDirector may spawn, and when.

@export var enemy: EnemyData
## Relative chance among the entries currently allowed.
@export var weight: float = 1.0
## Not spawned until threat reaches this.
@export var min_threat: float = 0.0
## Not spawned once threat exceeds this (0 = no limit). E.g. the Shambler
## leaves the pool once the basics are learned.
@export var max_threat: float = 0.0


func allowed_at(threat: float) -> bool:
	return threat >= min_threat and (max_threat <= 0.0 or threat <= max_threat)


func cost() -> float:
	return enemy.threat_cost if enemy != null else 0.0
