extends RefCounted
class_name DamageTypes

const PHYSICAL: String = "physical"
const MAGICAL: String = "magical"

const FIRE: String = "fire"
const ICE: String = "ice"
const LIGHTNING: String = "lightning"
const POISON: String = "poison"
const TRUE_DAMAGE: String = "true_damage"

static func is_valid_type(damage_type: String) -> bool:
	return damage_type in [
		PHYSICAL,
		MAGICAL,
		FIRE,
		ICE,
		LIGHTNING,
		POISON,
		TRUE_DAMAGE
	]
