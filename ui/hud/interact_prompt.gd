class_name InteractPrompt
extends Label
## Floats "[F] Open" above the nearest interactable in reach. Hidden on touch,
## where the Interact button does this job.

const HEIGHT_ABOVE: float = 1.6

@export var player: Node3D

var _key: String = "F"
var _enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 6)
	visible = false


func set_scheme(kind: InputRouter.SchemeKind) -> void:
	_enabled = kind != InputRouter.SchemeKind.TOUCH
	_key = "A" if kind == InputRouter.SchemeKind.GAMEPAD else "F"


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not _enabled or player == null or camera == null:
		visible = false
		return
	var target: Interactable = Interactable.nearest_in_range(get_tree(), player.global_position)
	if target == null:
		visible = false
		return
	text = "[%s] %s" % [_key, target.prompt]
	var screen: Vector2 = camera.unproject_position(
		target.world_position() + Vector3.UP * HEIGHT_ABOVE
	)
	reset_size()
	position = screen - Vector2(size.x * 0.5, size.y)
	visible = true
