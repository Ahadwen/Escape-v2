extends "res://tests/framework/test_case.gd"

const PoiIndicatorsScript := preload("res://ui/hud/poi_indicators.gd")
const RunInfoScript := preload("res://ui/hud/run_info.gd")


func test_point_inside_rect_is_unchanged() -> void:
	var rect: Rect2 = Rect2(0, 0, 100, 50)
	assert_eq(PoiIndicatorsScript.clamp_to_rect_edge(rect, Vector2(60, 30)), Vector2(60, 30))


func test_point_to_the_right_clamps_to_right_edge() -> void:
	var rect: Rect2 = Rect2(0, 0, 100, 50)
	assert_eq(PoiIndicatorsScript.clamp_to_rect_edge(rect, Vector2(500, 25)), Vector2(100, 25))


func test_point_above_clamps_to_top_edge() -> void:
	var rect: Rect2 = Rect2(0, 0, 100, 50)
	assert_eq(PoiIndicatorsScript.clamp_to_rect_edge(rect, Vector2(50, -400)), Vector2(50, 0))


func test_diagonal_point_hits_nearest_edge() -> void:
	var rect: Rect2 = Rect2(0, 0, 100, 50)
	var edge: Vector2 = PoiIndicatorsScript.clamp_to_rect_edge(rect, Vector2(150, 75))
	# Center (50, 25), offset (100, 50): the right edge is reached at half the
	# offset, so it lands on the corner.
	assert_eq(edge, Vector2(100, 50))


func test_format_time() -> void:
	assert_eq(RunInfoScript.format_time(0.0), "00:00")
	assert_eq(RunInfoScript.format_time(75.9), "01:15")
	assert_eq(RunInfoScript.format_time(3600.0), "60:00")
