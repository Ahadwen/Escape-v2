class_name ZoneData
extends Resource
## A zone: how it looks (named visual slots, greybox values for now), its
## obstacle kit, hazards, enemy variants and rules. Levels blend from the
## neutral zone toward the run's destination zone (see LevelTheme).

@export var id: StringName
@export var display_name: String

@export_group("Atmosphere")
@export var ground_color_a: Color = Color(0.36, 0.48, 0.32)
@export var ground_color_b: Color = Color(0.33, 0.45, 0.30)
@export var background_color: Color = Color(0.11, 0.12, 0.15)
@export var ambient_color: Color = Color(0.75, 0.8, 0.9)
@export var ambient_energy: float = 0.5
@export var sun_color: Color = Color(1, 1, 1)
@export var sun_energy: float = 1.1
@export var fog_color: Color = Color(0.5, 0.5, 0.55)
## 0 = no fog.
@export var fog_density: float = 0.0
## Drifting particles around the player (embers, mist). Alpha 0 = none.
@export var particle_color: Color = Color(1, 1, 1, 0)

@export_group("Terrain")
@export var obstacle_kit: Array[ObstacleKind] = []

@export_group("Hazards and rules")
@export var hazards: Array[HazardRule] = []
## Every hit you take sets you burning (Inferno).
@export var hits_ignite: bool = false
@export var burn_duration: float = 2.0
@export var burn_tick: float = 1.0
@export var burn_damage: float = 6.0

@export_group("Enemies")
@export var enemy_variants: Array[EnemyVariant] = []


func variant_for(base_id: StringName) -> EnemyData:
	for entry: EnemyVariant in enemy_variants:
		if entry.base_id == base_id:
			return entry.variant
	return null
