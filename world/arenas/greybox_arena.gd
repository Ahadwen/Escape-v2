extends Node3D
## Hand-built test arena for M1-M4. Wires input to the player and bakes the
## navmesh at runtime (the same way procedural levels will in M5).

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _input_router: InputRouter = $InputRouter
@onready var _player_controller: PlayerController = $Player/PlayerController
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar


func _ready() -> void:
	_bake_navigation()
	_input_router.intent_emitted.connect(_player_controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)
	_input_router.aim_preview_changed.connect(_aim_presenter.show_preview)
	_input_router.aim_preview_ended.connect(_aim_presenter.clear_preview)
	_input_router.scheme_changed.connect(_ability_bar.set_scheme)
	_ability_bar.set_scheme(_input_router.active_kind)


## Bakes from collision shapes on the world layer (fast and reliable at runtime,
## unlike parsing visual meshes back from the GPU).
func _bake_navigation() -> void:
	_nav_region.bake_navigation_mesh(false)
	if _nav_region.navigation_mesh.get_polygon_count() == 0:
		push_error("Navigation mesh baked with no polygons; click-to-move will not work.")


func _on_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent:
		_move_marker.show_at((intent as MoveToPointIntent).point)
