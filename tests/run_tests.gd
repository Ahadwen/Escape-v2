extends SceneTree
## Minimal headless test runner.
##
## Usage:
##   godot --headless --path . -s res://tests/run_tests.gd
##   godot --headless --path . -s res://tests/run_tests.gd -- unit/input
##
## The optional argument after `--` restricts the run to files whose path
## contains that text. Exits with code 0 if every test passes, 1 otherwise.

const MetaProgressScript := preload("res://meta/meta_progress.gd")
const TestCase := preload("res://tests/framework/test_case.gd")
const TEST_ROOT := "res://tests"
const SKIP_DIRS: Array[String] = ["framework"]

## Every failure, repeated in a summary at the end of the run.
var _failure_summary: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	# Run once the tree is live, so nodes added by tests are really inside it
	# (global transforms, groups and is_inside_tree() all work).
	_run_all.call_deferred()


func _run_all() -> void:
	var missing: PackedStringArray = _unregistered_classes()
	if not missing.is_empty():
		print("Godot hasn't registered these script classes yet: %s" % ", ".join(missing))
		print("Run this once, then run the tests again:")
		print("  godot --headless --path . --import")
		quit(1)
		return
	# Tests never read or write the real meta save.
	MetaProgressScript.saving_enabled = false
	var filter: String = ""
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if not user_args.is_empty():
		filter = user_args[0]

	var files: Array[String] = []
	_collect_test_files(TEST_ROOT, files)
	files.sort()

	var passed: int = 0
	var failed: int = 0

	for path: String in files:
		if not filter.is_empty() and not path.contains(filter):
			continue
		var result: Vector2i = _run_file(path)
		passed += result.x
		failed += result.y

	print("")
	if not _failure_summary.is_empty():
		print("Failures:")
		for line: String in _failure_summary:
			print("  " + line)
		print("")
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)


## Runs every test_ method in one file. Returns (passed, failed).
func _run_file(path: String) -> Vector2i:
	var script: GDScript = load(path) as GDScript
	if script == null or not script.can_instantiate():
		_report("FAIL  %s: could not load script (see errors above)" % path)
		return Vector2i(0, 1)

	var instance: Object = script.new()
	if not instance is TestCase:
		_report("FAIL  %s: does not extend tests/framework/test_case.gd" % path)
		return Vector2i(0, 1)
	var test_case: TestCase = instance as TestCase

	var passed: int = 0
	var failed: int = 0
	var seen: Dictionary = {}

	print(path)
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_") or seen.has(method_name):
			continue
		seen[method_name] = true

		test_case._reset()
		test_case.before_each()
		test_case.call(method_name)
		test_case.after_each()
		test_case._cleanup()

		var failures: PackedStringArray = test_case._get_failures()
		if failures.is_empty():
			passed += 1
			print("  PASS  %s" % method_name)
		else:
			failed += 1
			print("  FAIL  %s" % method_name)
			for failure: String in failures:
				print("        %s" % failure)
				_failure_summary.append("%s :: %s: %s" % [path, method_name, failure])

	return Vector2i(passed, failed)


func _report(line: String) -> void:
	print(line)
	_failure_summary.append(line)


func _collect_test_files(dir_path: String, out: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			out.append(dir_path.path_join(file_name))
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		if sub_dir in SKIP_DIRS:
			continue
		_collect_test_files(dir_path.path_join(sub_dir), out)


## Script classes declared in the project that Godot's class cache doesn't
## know about (new files since the last import).
func _unregistered_classes() -> PackedStringArray:
	var known: Dictionary = {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		known[String(entry["class"])] = true
	var missing: PackedStringArray = PackedStringArray()
	var scripts: Array[String] = []
	_collect_scripts("res://", scripts)
	for path: String in scripts:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var first: String = file.get_line().strip_edges()
		if first.begins_with("class_name "):
			var name: String = first.trim_prefix("class_name ").split(" ")[0]
			if not known.has(name):
				missing.append(name)
	return missing


func _collect_scripts(dir_path: String, out: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			out.append(dir_path.path_join(file_name))
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		if not sub_dir.begins_with("."):
			_collect_scripts(dir_path.path_join(sub_dir), out)
