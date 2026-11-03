class_name EnemyData
extends Resource
## Base for enemy definitions. Subclasses add behaviour parameters and create
## the matching EnemyBrain. Enemies have no HP: they can't be killed, only
## outlasted.

@export var id: StringName
@export var display_name: String
@export var color: Color = Color(0.85, 0.3, 0.3)

@export_group("Stats")
@export var move_speed: float = 4.0
@export var armour: float = 0.0
@export var elemental_resist: float = 0.0

@export_group("Attack")
@export var damage: float = 30.0
@export var damage_type: DamageEvent.DamageType = DamageEvent.DamageType.PHYSICAL
## Seconds between attacks.
@export var attack_cooldown: float = 1.2

@export_group("Awareness")
## Notices targets within this distance.
@export var sight_range: float = 14.0
## Gives up on a target further than this. 0 = never gives up.
@export var lose_interest_range: float = 22.0

@export_group("Lifetime")
@export var lifetime_min: float = 15.0
@export var lifetime_max: float = 22.0
## Seconds of visible warning before despawning.
@export var despawn_warning: float = 2.0

@export_group("Director")
## How much of the threat budget one of these costs (used in M4).
@export var threat_cost: float = 1.0


func get_base_stats() -> Dictionary[StringName, float]:
	return {
		StatIds.MOVE_SPEED: move_speed,
		StatIds.ARMOUR: armour,
		StatIds.ELEMENTAL_RESIST: elemental_resist,
	}


## Override in subclasses.
func create_brain() -> EnemyBrain:
	return EnemyBrain.new()
