class_name Player
extends CharacterBody3D
## The player actor. Sets up its components from the chosen character.

@export var character: CharacterData

@onready var stats: StatsComponent = $StatsComponent
@onready var movement: ActorMovement = $ActorMovement
@onready var abilities: AbilityCaster = $AbilityCaster


func _ready() -> void:
	if character == null:
		push_warning("Player has no CharacterData assigned.")
		return
	stats.initialize(character.get_base_stats())
	abilities.set_abilities(character.get_abilities())
