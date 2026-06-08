extends RefCounted
class_name TestCase

var _current_failures: Array[Dictionary] = []


func run_case(case_name: String, callable: Callable) -> Dictionary:
	_current_failures.clear()
	callable.call()

	return {
		"name": case_name,
		"passed": _current_failures.is_empty(),
		"failures": _current_failures.duplicate(true)
	}


func assert_equal(actual, expected, message: String = "") -> void:
	if actual == expected:
		return

	_fail(
		_message_or_default(
			message,
			"Expected %s, got %s." % [var_to_str(expected), var_to_str(actual)]
		)
	)


func assert_true(value: bool, message: String = "") -> void:
	if value:
		return

	_fail(_message_or_default(message, "Expected condition to be true."))


func assert_false(value: bool, message: String = "") -> void:
	if not value:
		return

	_fail(_message_or_default(message, "Expected condition to be false."))


func assert_has_key(dictionary: Dictionary, key, message: String = "") -> void:
	if dictionary.has(key):
		return

	_fail(
		_message_or_default(
			message,
			"Expected dictionary to contain key %s." % var_to_str(key)
		)
	)


func assert_size(collection, expected_size: int, message: String = "") -> void:
	var actual_size: int = collection.size()
	if actual_size == expected_size:
		return

	_fail(
		_message_or_default(
			message,
			"Expected size %d, got %d." % [expected_size, actual_size]
		)
	)


func _fail(message: String) -> void:
	_current_failures.append({"message": message})


func _message_or_default(message: String, default_message: String) -> String:
	if message.strip_edges() != "":
		return message

	return default_message
