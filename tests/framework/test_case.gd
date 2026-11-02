extends RefCounted
## Base class for tests run by res://tests/run_tests.gd.
##
## Test files live under res://tests/, are named test_*.gd, extend this script
## by path, and define methods starting with test_. Assertions record failures
## rather than aborting, so every assertion in a test is reported.

var _failures: PackedStringArray = PackedStringArray()


## Called before each test method. Override to set up fixtures.
func before_each() -> void:
	pass


## Called after each test method. Override to tear down fixtures.
func after_each() -> void:
	pass


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("expected true", message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("expected false", message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _variants_equal(actual, expected):
		_fail("expected %s, got %s" % [var_to_str(expected), var_to_str(actual)], message)


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if _variants_equal(actual, unexpected):
		_fail("did not expect %s" % var_to_str(unexpected), message)


func assert_almost_eq(
	actual: float, expected: float, tolerance: float = 0.0001, message: String = ""
) -> void:
	if absf(actual - expected) > tolerance:
		_fail("expected %f ± %f, got %f" % [expected, tolerance, actual], message)


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		_fail("expected null, got %s" % var_to_str(value), message)


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		_fail("expected a non-null value", message)


func fail(message: String) -> void:
	_fail("failed", message)


# --- Runner interface -------------------------------------------------------


func _reset() -> void:
	_failures = PackedStringArray()


func _get_failures() -> PackedStringArray:
	return _failures


func _fail(reason: String, message: String) -> void:
	_failures.append(reason if message.is_empty() else "%s: %s" % [message, reason])


func _variants_equal(a: Variant, b: Variant) -> bool:
	# StringName and String compare equal by content, which is what tests want.
	if (
		typeof(a) in [TYPE_STRING, TYPE_STRING_NAME]
		and typeof(b) in [TYPE_STRING, TYPE_STRING_NAME]
	):
		return String(a) == String(b)
	return typeof(a) == typeof(b) and a == b
