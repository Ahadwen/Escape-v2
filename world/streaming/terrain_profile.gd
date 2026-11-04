class_name TerrainProfile
extends Resource
## How streamed terrain is generated and loaded. (M7's LevelTheme will feed
## per-zone values into this.)

@export_group("Streaming")
## Width of a square chunk, metres.
@export var chunk_size: float = 32.0
## Chunks within this many chunks of the player are loaded.
@export var load_radius: int = 2
## Chunks further than this are freed. Larger than load_radius to avoid churn.
@export var unload_radius: int = 3

@export_group("Obstacles")
@export var obstacles_min: int = 7
@export var obstacles_max: int = 12
## Chance that an obstacle is a compound shape instead (an L-shaped corner or
## a tight cluster of pillars): corners to duck round and pockets to get
## caught in.
@export_range(0.0, 1.0) var compound_chance: float = 0.3
## Minimum clear gap between obstacles (also across chunk borders).
@export var obstacle_gap: float = 2.0
## No obstacles within this radius of the level start.
@export var start_clear_radius: float = 8.0

@export_group("Points of interest")
@export_range(0.0, 1.0) var crystal_chance: float = 0.3
@export_range(0.0, 1.0) var chest_chance: float = 0.07
## No safehouses within this many chunks of the start.
@export var safehouse_min_distance: int = 3
## Safehouse chance per chunk grows by this much per chunk of distance beyond
## the minimum, up to safehouse_max_chance.
@export var safehouse_chance_per_distance: float = 0.04
@export_range(0.0, 1.0) var safehouse_max_chance: float = 0.0
## Clear space kept around points of interest.
@export var poi_clearance: float = 3.5

@export_group("Timed safehouses")
## Safehouses open on a timer rather than being scattered through chunks:
## one opens every interval_min..max seconds (the previous one closes), a
## distance ahead of where you've been heading. 0 = off.
@export var safehouse_interval_min: float = 75.0
@export var safehouse_interval_max: float = 110.0
@export var safehouse_distance_min: float = 45.0
@export var safehouse_distance_max: float = 65.0
## Opens within this angle either side of your heading.
@export var safehouse_spread_degrees: float = 70.0

@export_group("Look")
@export var ground_color_a: Color = Color(0.36, 0.48, 0.32)
@export var ground_color_b: Color = Color(0.33, 0.45, 0.30)
@export var obstacle_color: Color = Color(0.58, 0.58, 0.62)


func safehouse_chance(chunk_distance: int) -> float:
	if chunk_distance < safehouse_min_distance:
		return 0.0
	var steps: int = chunk_distance - safehouse_min_distance
	return minf(steps * safehouse_chance_per_distance, safehouse_max_chance)
