class_name Player
extends CharacterBody3D
## The player actor. Sets up its components from the chosen character and
## handles death.

signal died

const GROUP: StringName = &"player"

@export var character: CharacterData

var is_dead: bool = false

@onready var stats: StatsComponent = $StatsComponent
@onready var movement: ActorMovement = $ActorMovement
@onready var abilities: AbilityCaster = $AbilityCaster
@onready var health: HealthComponent = $HealthComponent
@onready var status: StatusEffectHost = $StatusEffectHost
@onready var controller: PlayerController = $PlayerController
@onready var visual: Node3D = $Visual
@onready var cards: CardInventory = $CardInventory
@onready var wallet: Wallet = $Wallet
@onready var events: PlayerEvents = $PlayerEvents


func _ready() -> void:
	add_to_group(GROUP)
	health.died.connect(_on_died)
	# The character chosen in the Nexus Armory, if any.
	var chosen: CharacterData = MetaProgress.selected_character()
	if chosen != null:
		character = chosen
	if character == null:
		push_warning("Player has no CharacterData assigned.")
		return
	stats.initialize(character.get_base_stats())
	MetaProgress.apply_to(stats.block)
	health.refresh_max(true)
	abilities.set_abilities(character.get_abilities())


func _physics_process(_delta: float) -> void:
	movement.rooted = status.is_rooted()


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
