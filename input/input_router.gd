class_name InputRouter
extends Node
## Owns the three input schemes, keeps exactly one active, and forwards its
## intents. Switches scheme automatically to whichever device was used last.

signal intent_emitted(intent: PlayerIntent)
signal scheme_changed(kind: SchemeKind)

enum SchemeKind { PC, GAMEPAD, TOUCH }

const NO_SCHEME: int = -1
const MOUSE_MOTION_SWITCH_THRESHOLD: float = 4.0
const STICK_SWITCH_THRESHOLD: float = 0.5

@export var camera: Camera3D:
	set(value):
		camera = value
		for scheme: InputScheme in _schemes.values():
			scheme.camera = value
@export var pc_scheme: PCInputScheme
@export var gamepad_scheme: GamepadInputScheme
@export var touch_scheme: TouchInputScheme
## Switch scheme on the last-used device. Turned off by the debug cycle key.
@export var auto_detect: bool = true

var active_kind: SchemeKind = SchemeKind.PC

var _schemes: Dictionary[int, InputScheme] = {}


func _ready() -> void:
	_schemes = {
		SchemeKind.PC: pc_scheme,
		SchemeKind.GAMEPAD: gamepad_scheme,
		SchemeKind.TOUCH: touch_scheme,
	}
	for scheme: InputScheme in _schemes.values():
		scheme.camera = camera
		scheme.intent_emitted.connect(_on_scheme_intent)
	_activate(_initial_kind())


func get_active_scheme() -> InputScheme:
	return _schemes[active_kind]


func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed(InputActions.DEBUG_CYCLE_SCHEME):
		auto_detect = false
		var next: int = (active_kind + 1) % SchemeKind.size()
		_activate(next as SchemeKind)
		print("Input scheme forced to %s (auto-detect off)" % SchemeKind.keys()[active_kind])
		return
	if not auto_detect:
		return
	var kind: int = _kind_for_event(event)
	if kind != NO_SCHEME and kind != active_kind:
		_activate(kind as SchemeKind)


func _on_scheme_intent(intent: PlayerIntent) -> void:
	intent_emitted.emit(intent)


func _activate(kind: SchemeKind) -> void:
	for other: int in _schemes:
		if other != kind:
			_schemes[other].deactivate()
	active_kind = kind
	_schemes[kind].activate()
	scheme_changed.emit(kind)


func _initial_kind() -> SchemeKind:
	if OS.has_feature("mobile"):
		return SchemeKind.TOUCH
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		return SchemeKind.TOUCH
	return SchemeKind.PC


## Which scheme a raw event belongs to, or NO_SCHEME. Emulated events (touch
## from mouse, mouse from touch) are ignored so they can't cause flip-flopping.
func _kind_for_event(event: InputEvent) -> int:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return NO_SCHEME
	var kind: int = NO_SCHEME
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		kind = SchemeKind.TOUCH
	elif event is InputEventMouseButton or event is InputEventKey:
		kind = SchemeKind.PC
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if motion.relative.length() > MOUSE_MOTION_SWITCH_THRESHOLD:
			kind = SchemeKind.PC
	elif event is InputEventJoypadButton:
		kind = SchemeKind.GAMEPAD
	elif event is InputEventJoypadMotion:
		var stick: InputEventJoypadMotion = event as InputEventJoypadMotion
		if absf(stick.axis_value) > STICK_SWITCH_THRESHOLD:
			kind = SchemeKind.GAMEPAD
	return kind
