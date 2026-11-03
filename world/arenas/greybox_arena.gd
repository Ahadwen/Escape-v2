extends Node3D
## Hand-built test arena for M1-M4. Wires input to the player, bakes the
## navmesh at runtime (the same way procedural levels will in M5), and
## restarts after the player dies.

const RESTART_DELAY: float = 2.5

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _input_router: InputRouter = $InputRouter
@onready var _player: Player = $Player
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar
@onready var _death_label: Label = $HUD/DeathLabel
@onready var _spawner: DebugSpawner = $DebugSpawner


func _ready() -> void:
	_bake_navigation()
	_input_router.intent_emitted.connect(_player.controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)
	_input_router.aim_preview_changed.connect(_aim_presenter.show_preview)
	_input_router.aim_preview_ended.connect(_aim_presenter.clear_preview)
	_input_router.scheme_changed.connect(_ability_bar.set_scheme)
	_ability_bar.set_scheme(_input_router.active_kind)
	_player.died.connect(_on_player_died)
	_death_label.visible = false
	_spawner.start()


## Bakes from collision shapes on the world layer (fast and reliable at runtime,
## unlike parsing visual meshes back from the GPU).
func _bake_navigation() -> void:
	_nav_region.bake_navigation_mesh(false)
	if _nav_region.navigation_mesh.get_polygon_count() == 0:
		push_error("Navigation mesh baked with no polygons; click-to-move will not work.")


func _on_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent and not _player.is_dead:
		_move_marker.show_at((intent as MoveToPointIntent).point)


func _on_player_died() -> void:
	_aim_presenter.clear_preview()
	_death_label.visible = true
	await get_tree().create_timer(RESTART_DELAY).timeout
	get_tree().reload_current_scene()
