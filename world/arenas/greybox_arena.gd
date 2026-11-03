extends Node3D
## Hand-built test arena for M1-M4. Bakes the navmesh at runtime, places the
## safehouse and crystals at random candidate spots, runs the threat
## director, and restarts after the player escapes or dies. Infinite streamed
## terrain replaces this in M5.

const RESTART_DELAY_DEATH: float = 2.5
const RESTART_DELAY_ESCAPE: float = 4.0
const CRYSTAL_COUNT: int = 5

@export var crystal_scene: PackedScene = preload("res://world/pois/health_crystal.tscn")
@export var safehouse_scene: PackedScene = preload("res://world/pois/safehouse.tscn")

var _finished: bool = false

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _input_router: InputRouter = $InputRouter
@onready var _player: Player = $Player
@onready var _director: ThreatDirector = $ThreatDirector
@onready var _pois: Node3D = $Pois
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar
@onready var _message: Label = $HUD/MessageLabel


func _ready() -> void:
	_bake_navigation()
	_input_router.intent_emitted.connect(_player.controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)
	_input_router.aim_preview_changed.connect(_aim_presenter.show_preview)
	_input_router.aim_preview_ended.connect(_aim_presenter.clear_preview)
	_input_router.scheme_changed.connect(_ability_bar.set_scheme)
	_ability_bar.set_scheme(_input_router.active_kind)
	_player.died.connect(_on_player_died)
	_message.visible = false
	_place_pois()
	# Let the navigation map sync before the director queries it.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_director.start()


## Bakes from collision shapes on the world layer (fast and reliable at runtime,
## unlike parsing visual meshes back from the GPU).
func _bake_navigation() -> void:
	_nav_region.bake_navigation_mesh(false)
	if _nav_region.navigation_mesh.get_polygon_count() == 0:
		push_error("Navigation mesh baked with no polygons; click-to-move will not work.")


func _place_pois() -> void:
	var safehouse_spots: Array[Node] = $SafehouseSpots.get_children()
	var crystal_spots: Array[Node] = $CrystalSpots.get_children()
	crystal_spots.shuffle()
	if not safehouse_spots.is_empty():
		var safehouse: Safehouse = safehouse_scene.instantiate() as Safehouse
		safehouse.position = (safehouse_spots.pick_random() as Node3D).position
		safehouse.entered.connect(_on_safehouse_entered)
		_pois.add_child(safehouse)
	for i: int in mini(CRYSTAL_COUNT, crystal_spots.size()):
		var crystal: Node3D = crystal_scene.instantiate() as Node3D
		crystal.position = (crystal_spots[i] as Node3D).position
		_pois.add_child(crystal)


func _on_intent(intent: PlayerIntent) -> void:
	if intent is MoveToPointIntent and not _finished:
		_move_marker.show_at((intent as MoveToPointIntent).point)


func _on_safehouse_entered(_who: Player) -> void:
	if _finished:
		return
	_finished = true
	_director.stop(true)
	_player.controller.enabled = false
	_player.abilities.cancel_all()
	_player.movement.stop()
	_aim_presenter.clear_preview()
	_show_message("Escaped in %s" % RunInfo.format_time(_director.elapsed))
	await get_tree().create_timer(RESTART_DELAY_ESCAPE).timeout
	get_tree().reload_current_scene()


func _on_player_died() -> void:
	if _finished:
		return
	_finished = true
	_director.stop(false)
	_aim_presenter.clear_preview()
	_show_message("Caught after %s" % RunInfo.format_time(_director.elapsed))
	await get_tree().create_timer(RESTART_DELAY_DEATH).timeout
	get_tree().reload_current_scene()


func _show_message(text: String) -> void:
	_message.text = text
	_message.visible = true
