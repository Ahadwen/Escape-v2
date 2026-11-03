class_name Decoy
extends Node3D
## A lure. Has HP and a high-priority Targetable, so enemies go for it
## instead of the player. Disappears when destroyed or when its time is up.

var _max_hp: float = 100.0
var _remaining: float = 4.0

@onready var health: HealthComponent = $HealthComponent
@onready var visual: Node3D = $Visual


## Call before adding to the tree.
func configure(max_hp: float, lifetime: float) -> void:
	_max_hp = max_hp
	_remaining = lifetime


func _ready() -> void:
	health.fallback_max = _max_hp
	health.refresh_max(true)
	health.died.connect(queue_free)
	health.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()


func _on_damaged(_amount: float, _event: DamageEvent) -> void:
	# Quick squash so hits read clearly.
	var tween: Tween = create_tween()
	visual.scale = Vector3(1.15, 0.85, 1.15)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.15)
