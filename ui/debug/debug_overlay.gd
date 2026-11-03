class_name DebugOverlay
extends Label
## Debug builds only: live readout of input and movement state, top-left.

@export var input_router: InputRouter
@export var movement: ActorMovement
@export var nav_region: NavigationRegion3D
## Optional.
@export var streamer: WorldStreamer

var _last_intent: String = "-"


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 13)
	position = Vector2(12.0, 12.0)
	input_router.intent_emitted.connect(_on_intent)


func _process(_delta: float) -> void:
	var polygons: int = 0
	if nav_region != null and nav_region.navigation_mesh != null:
		polygons = nav_region.navigation_mesh.get_polygon_count()
	text = (
		"\n"
		. join(
			[
				"scheme: %s" % InputRouter.SchemeKind.keys()[input_router.active_kind],
				"last intent: %s" % _last_intent,
				(
					"mode: %s  override: %s"
					% [ActorMovement.Mode.keys()[movement.mode], movement.has_override()]
				),
				"speed: %.2f" % movement.current_speed(),
				"navmesh polygons: %d" % polygons,
				"path points left: %d" % movement.path_points_remaining(),
				"joypads: %s" % str(Input.get_connected_joypads()),
				"enemies: %d" % get_tree().get_nodes_in_group(Enemy.GROUP).size(),
				_streamer_line(),
			]
		)
	)


func _on_intent(intent: PlayerIntent) -> void:
	if intent is AimIntent:
		return
	var script: Script = intent.get_script()
	_last_intent = String(script.get_global_name()) if script != null else "?"


func _streamer_line() -> String:
	if streamer == null:
		return ""
	var level_node: Node = get_tree().current_scene
	var theme: LevelTheme = level_node.get("theme") as LevelTheme
	var zone_text: String = "no theme"
	if theme != null:
		zone_text = "zone %s  intensity %.2f" % [theme.zone.id, theme.intensity]
	var burning: bool = movement.body.get_node("StatusEffectHost").has_effect(BurnEffect.ID)
	return (
		"level %d  %s  burning %s\nseed %d  chunk %s  loaded %d"
		% [
			RunState.level_index + 1,
			zone_text,
			burning,
			streamer.run_seed,
			streamer.current_chunk(),
			streamer.loaded_count()
		]
	)
