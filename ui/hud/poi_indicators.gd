class_name PoiIndicators
extends Control
## Arrows at the screen edge pointing to discovered points of interest that
## are off-screen.

@export var margin: float = 36.0
@export var arrow_size: float = 16.0
@export var font_size: int = 13


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen: Rect2 = get_viewport().get_visible_rect()
	var inner: Rect2 = screen.grow(-margin)
	var to_local: Transform2D = get_global_transform_with_canvas().affine_inverse()
	for node: Node in get_tree().get_nodes_in_group(Discoverable.GROUP):
		var poi: Discoverable = node as Discoverable
		if poi == null or not poi.is_discovered or not poi.show_edge_indicator:
			continue
		if poi.target == null or not is_instance_valid(poi.target):
			continue
		var point: Vector2 = camera.unproject_position(poi.world_position())
		if inner.has_point(point):
			continue
		var edge: Vector2 = clamp_to_rect_edge(inner, point)
		var direction: Vector2 = (point - inner.get_center()).normalized()
		_draw_arrow(to_local * edge, direction, poi.indicator_color, poi.label)


## Where the line from the rect's centre toward point crosses the rect edge.
static func clamp_to_rect_edge(rect: Rect2, point: Vector2) -> Vector2:
	var center: Vector2 = rect.get_center()
	var offset: Vector2 = point - center
	if offset == Vector2.ZERO:
		return center
	var half: Vector2 = rect.size * 0.5
	var scale_x: float = half.x / absf(offset.x) if offset.x != 0.0 else INF
	var scale_y: float = half.y / absf(offset.y) if offset.y != 0.0 else INF
	return center + offset * minf(1.0, minf(scale_x, scale_y))


func _draw_arrow(at: Vector2, direction: Vector2, color: Color, text: String) -> void:
	var side: Vector2 = direction.orthogonal() * arrow_size * 0.6
	var tip: Vector2 = at + direction * arrow_size
	draw_colored_polygon(PackedVector2Array([tip, at + side, at - side]), color)
	if text.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var label_at: Vector2 = (
		at - direction * (arrow_size + 6.0) - Vector2(text_size.x * 0.5, -text_size.y * 0.3)
	)
	draw_string(font, label_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
