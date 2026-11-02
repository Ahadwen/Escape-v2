extends Node3D
## Hand-built test arena for M1-M4. Wires input to the player and bakes the
## navmesh at runtime (the same way procedural levels will in M5).

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _input_router: InputRouter = $InputRouter
@onready var _player_controller: PlayerController = $Player/PlayerController
@onready var _move_marker: MoveMarker = $MoveMarker


func _ready() -> void:
	_nav_region.bake_navigation_mesh(false)
	_input_router.intent_emitted.connect(_player_controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)


func _on_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent:
		_move_marker.show_at((intent as MoveToPointIntent).point)
