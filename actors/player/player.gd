class_name Player
extends CharacterBody3D
## The player actor. Sets up its components from the chosen character and
## handles death.

signal died

@export var character: CharacterData

var is_dead: bool = false

@onready var stats: StatsComponent = $StatsComponent
@onready var movement: ActorMovement = $ActorMovement
@onready var abilities: AbilityCaster = $AbilityCaster
@onready var health: HealthComponent = $HealthComponent
@onready var status: StatusEffectHost = $StatusEffectHost
@onready var controller: PlayerController = $PlayerController
@onready var visual: Node3D = $Visual


func _ready() -> void:
	health.died.connect(_on_died)
	if character == null:
		push_warning("Player has no CharacterData assigned.")
		return
	stats.initialize(character.get_base_stats())
	health.refresh_max(true)
	abilities.set_abilities(character.get_abilities())


func _on_died() -> void:
	is_dead = true
	controller.enabled = false
	abilities.cancel_all()
	movement.stop()
	status.clear()
	# Topple over so it's obvious.
	var tween: Tween = create_tween()
	tween.tween_property(visual, "rotation:x", -PI * 0.5, 0.4)
	died.emit()
