class_name HazardRule
extends Resource
## How a zone's ground hazard appears during a level. Rates and caps scale
## with zone intensity and threat.

@export var hazard_scene: PackedScene
## Patches per second at intensity 1, threat 0 ...
@export var base_rate: float = 0.12
## ... plus this much per point of threat.
@export var rate_per_threat: float = 0.04
## Most alive at once at intensity 1 (scaled down by intensity).
@export var max_alive: int = 6
## Spawn ring around the player (never on top of them).
@export var min_distance: float = 6.0
@export var max_distance: float = 18.0
