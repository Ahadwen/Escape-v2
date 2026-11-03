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
@export var obstacles_min: int = 6
@export var obstacles_max: int = 11
## Minimum clear gap between obstacles (also across chunk borders).
@export var obstacle_gap: float = 2.0
## No obstacles within this radius of the level start.
@export var start_clear_radius: float = 8.0

@export_group("Points of interest")
@export_range(0.0, 1.0) var crystal_chance: float = 0.3
## No safehouses within this many chunks of the start.
@export var safehouse_min_distance: int = 3
## Safehouse chance per chunk grows by this much per chunk of distance beyond
## the minimum, up to safehouse_max_chance.
@export var safehouse_chance_per_distance: float = 0.04
@export_range(0.0, 1.0) var safehouse_max_chance: float = 0.35
## Clear space kept around points of interest.
@export var poi_clearance: float = 3.5

@export_group("Look")
@export var ground_color_a: Color = Color(0.36, 0.48, 0.32)
@export var ground_color_b: Color = Color(0.33, 0.45, 0.30)
@export var obstacle_color: Color = Color(0.58, 0.58, 0.62)


func safehouse_chance(chunk_distance: int) -> float:
	if chunk_distance < safehouse_min_distance:
		return 0.0
	var steps: int = chunk_distance - safehouse_min_distance
	return minf(steps * safehouse_chance_per_distance, safehouse_max_chance)
