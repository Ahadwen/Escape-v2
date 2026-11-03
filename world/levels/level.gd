extends Node3D
## One level: streamed infinite terrain, the threat director, and the player.
## Ends when the player reaches a safehouse or dies, then restarts.
## (M7 adds the shop and moving on to the next level.)

const RESTART_DELAY_DEATH: float = 2.5
const RESTART_DELAY_ESCAPE: float = 4.0

## 0 = random seed each run.
@export var fixed_seed: int = 0
@export var level_index: int = 0
@export var card_library: CardLibrary = preload("res://items/data/card_library.tres")

var _finished: bool = false

@onready var _streamer: WorldStreamer = $WorldStreamer
@onready var _input_router: InputRouter = $InputRouter
@onready var _player: Player = $Player
@onready var _director: ThreatDirector = $ThreatDirector
@onready var _move_marker: MoveMarker = $MoveMarker
@onready var _aim_presenter: AimPreviewPresenter = $AimPreviewPresenter
@onready var _ability_bar: AbilityBar = $HUD/AbilityBar
@onready var _message: Label = $HUD/MessageLabel
@onready var _card_bar: CardBar = $HUD/CardBar
@onready var _pickup_screen: CardPickupScreen = $PickupLayer/CardPickupScreen
@onready var _pause: PauseController = $PauseController


func _ready() -> void:
	var run_seed: int = fixed_seed if fixed_seed != 0 else randi()
	_streamer.start(run_seed, level_index)
	_streamer.safehouse_entered.connect(_on_safehouse_entered)
	_streamer.crystal_consumed.connect(_on_crystal_consumed)
	_pickup_screen.set_library(card_library)
	_input_router.intent_emitted.connect(_player.controller.handle_intent)
	_input_router.intent_emitted.connect(_on_intent)
	_input_router.aim_preview_changed.connect(_aim_presenter.show_preview)
	_input_router.aim_preview_ended.connect(_aim_presenter.clear_preview)
	_input_router.scheme_changed.connect(_on_scheme_changed)
	_on_scheme_changed(_input_router.active_kind)
	_player.died.connect(_on_player_died)
	_message.visible = false
	_player.wallet.add(roundi(_player.stats.get_value(StatIds.GOLD_PER_LEVEL)))
	# Let the navigation map sync before the director queries it.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_director.start()


func _on_scheme_changed(kind: InputRouter.SchemeKind) -> void:
	_ability_bar.set_scheme(kind)
	_card_bar.set_scheme(kind)
	_pause.set_touch_controls_visible(kind == InputRouter.SchemeKind.TOUCH)


func _on_crystal_consumed() -> void:
	_player.wallet.add(roundi(_player.stats.get_value(StatIds.GOLD_PER_CRYSTAL)))


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
