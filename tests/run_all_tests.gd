extends SceneTree

const TEST_SUITES: Array[String] = [
	"res://tests/unit/test_damage_resolver.gd",
	"res://tests/unit/test_reward_resolver.gd",
	"res://tests/unit/test_spawn_timeline_definition.gd",
	"res://tests/unit/test_run_state.gd",
	"res://tests/unit/test_level_up_option_service.gd"
]


func _init() -> void:
	var total_cases: int = 0
	var failed_cases: int = 0

	print("== Queen Survivors Unit Tests ==")

	for suite_path: String in TEST_SUITES:
		var script: Script = load(suite_path)
		if script == null:
			failed_cases += 1
			push_error("Failed to load test suite: %s" % suite_path)
			continue

		var suite = script.new()
		if suite == null or not suite.has_method("run"):
			failed_cases += 1
			push_error("Test suite missing run(): %s" % suite_path)
			continue

		var suite_name: String = suite_path.get_file()
		if suite.has_method("get_suite_name"):
			suite_name = String(suite.call("get_suite_name"))

		print("")
		print("-- %s --" % suite_name)

		var results: Array = suite.run()

		for result_variant in results:
			total_cases += 1
			var result: Dictionary = result_variant
			var passed: bool = bool(result.get("passed", false))
			var case_name: String = String(result.get("name", "unnamed_case"))

			if passed:
				print("PASS  %s" % case_name)
				continue

			failed_cases += 1
			print("FAIL  %s" % case_name)

			for failure_variant in result.get("failures", []):
				var failure: Dictionary = failure_variant
				print("  - %s" % String(failure.get("message", "Unknown failure.")))

	print("")
	print("== Summary ==")
	print("Cases: %d" % total_cases)
	print("Failures: %d" % failed_cases)

	quit(0 if failed_cases == 0 else 1)
