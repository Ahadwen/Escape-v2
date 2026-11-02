class_name TouchJoystick
extends Control
## On-screen analogue stick. The Control's rect is the touch zone; touching
## inside it grabs the stick. Read `output` (0..1 length, y down).

## A finger took hold of the stick.
signal grabbed
## The finger let go. final_output is the stick value just before release.
signal released(final_output: Vector2)

@export var radius: float = 90.0
@export_range(0.0, 0.9) var deadzone: float = 0.15
## If true, the stick base recentres wherever the finger lands in the zone.
@export var floating: bool = true
@export var base_color: Color = Color(1.0, 1.0, 1.0, 0.18)
@export var knob_color: Color = Color(1.0, 1.0, 1.0, 0.55)
## Optional text drawn in the middle of the stick (e.g. ability name).
@export var label: String = ""

## Current stick value. Read-only for other nodes.
var output: Vector2 = Vector2.ZERO
## Only an enabled joystick reacts to touches. Set by the touch scheme.
var enabled: bool = false:
	set(value):
		enabled = value
		_release()

var _finger: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_release()


func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and _finger == -1:
			var local: Vector2 = _viewport_to_local(touch.position)
			if Rect2(Vector2.ZERO, size).has_point(local):
				_finger = touch.index
				_center = local if floating else _rest_center()
				_move_knob(local)
				grabbed.emit()
				get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _finger:
			var final_output: Vector2 = output
			_release()
			released.emit(final_output)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == _finger:
			_move_knob(_viewport_to_local(drag.position))
			get_viewport().set_input_as_handled()


func _draw() -> void:
	if not enabled:
		return
	draw_circle(_center, radius, base_color)
	draw_circle(_knob, radius * 0.4, knob_color)
	if not label.is_empty():
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 14
		var text_size: Vector2 = font.get_string_size(
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
		)
		var baseline: Vector2 = (
			_rest_center() + Vector2(-text_size.x * 0.5, radius + font_size + 4.0)
		)
		draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


func is_held() -> bool:
	return _finger != -1


func _move_knob(local_position: Vector2) -> void:
	var offset: Vector2 = (local_position - _center).limit_length(radius)
	_knob = _center + offset
	output = InputMath.joystick_output(offset, radius, deadzone)
	queue_redraw()


func _release() -> void:
	_finger = -1
	_center = _rest_center()
	_knob = _center
	output = Vector2.ZERO
	queue_redraw()


func _rest_center() -> Vector2:
	return size * 0.5


func _viewport_to_local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _on_resized() -> void:
	if _finger == -1:
		_release()
