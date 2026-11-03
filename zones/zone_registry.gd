class_name ZoneRegistry
extends Resource
## The neutral zone (level 1, and what other zones blend from) and the
## destination zones a run can head toward.

@export var neutral: ZoneData
@export var destinations: Array[ZoneData] = []
## Zone intensity for each level (index = level, 0-based).
@export var level_intensity: PackedFloat32Array = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])


func intensity_for(level: int) -> float:
	if level_intensity.is_empty():
		return 0.0
	return level_intensity[clampi(level, 0, level_intensity.size() - 1)]


## Destination for a run, picked from its seed (so a seed replays the same run).
func destination_for_seed(run_seed: int) -> ZoneData:
	if destinations.is_empty():
		return neutral
	return destinations[posmod(run_seed, destinations.size())]
