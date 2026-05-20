extends RefCounted
class_name DirectionUtils

static func safe_normalized(direction: Vector2, fallback: Vector2 = Vector2.RIGHT) -> Vector2:
	if direction.length() <= 0.001:
		return fallback.normalized()

	return direction.normalized()

static func is_direction_valid(direction: Vector2) -> bool:
	return direction.length() > 0.001

static func direction_to_sign_x(direction: Vector2) -> int:
	if direction.x < -0.001:
		return -1

	if direction.x > 0.001:
		return 1

	return 0
