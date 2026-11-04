class_name EnemyData
extends Resource
## Base for enemy definitions. Subclasses add behaviour parameters and create
## the matching EnemyBrain. Enemies have no HP: they can't be killed, only
## outlasted.

## EVERYONE: player and enemies bump into it. PLAYER_ONLY: a crowd body
## (Shamblers) that blocks the player but hunters pass straight through.
## NOBODY: passes through everything but walls (mites).
enum BodyBlocking { EVERYONE, PLAYER_ONLY, NOBODY }

@export var id: StringName
@export var display_name: String
@export var color: Color = Color(0.85, 0.3, 0.3)
## Model and collision size relative to the base enemy (x/z width, y height).
@export var body_scale: Vector3 = Vector3.ONE
## What this enemy's body physically blocks.
@export var body_blocking: BodyBlocking = BodyBlocking.EVERYONE

@export_group("Stats")
@export var move_speed: float = 4.0
@export var armour: float = 0.0
@export var elemental_resist: float = 0.0

@export_group("Attack")
@export var damage: float = 30.0
@export var damage_type: DamageEvent.DamageType = DamageEvent.DamageType.PHYSICAL
## Seconds between attacks.
@export var attack_cooldown: float = 1.2

## Damage dealt to player-faction targets the enemy touches. 0 = none.
@export var contact_damage: float = 0.0
## Seconds before the same target can take contact damage again.
@export var contact_cooldown: float = 0.7
## Contact also pushes the target away this far (0 = no push).
@export var contact_knockback: float = 0.0

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
## Extra move speed gained over the enemy's life (0.25 = +25% by the end), so
## old enemies are more dangerous than fresh ones.
@export var speed_gain_over_life: float = 0.25

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
