## Catálogo central dos tipos de dano reconhecidos pelo gameplay.
##
## Utilizar estas constantes evita strings divergentes em:
## - weapons;
## - inimigos;
## - upgrades;
## - payloads;
## - resolução de fraquezas e resistências.
extends RefCounted
class_name DamageTypes

## Dano físico convencional.
const PHYSICAL: String = "physical"

## Dano mágico convencional.
const MAGICAL: String = "magical"

## Tipos já reservados para expansão futura do sistema.
const FIRE: String = "fire"
const ICE: String = "ice"
const LIGHTNING: String = "lightning"
const POISON: String = "poison"

## Dano previsto para ignorar defesa percentual quando aplicado ao player.
const TRUE_DAMAGE: String = "true_damage"

## Verifica se um identificador pertence ao catálogo reconhecido.
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
