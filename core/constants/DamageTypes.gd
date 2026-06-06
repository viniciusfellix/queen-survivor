## Catálogo central dos tipos de dano suportados pelo jogo.
##
## Responsabilidades:
## - evitar strings soltas espalhadas pelo projeto;
## - padronizar os tipos usados por DamagePayload, DamageResolver,
##   DamageComponentDefinition, EnemyDefinition e armas;
## - validar se um tipo de dano informado é reconhecido.
##
## Este arquivo não possui estado runtime.
## Ele funciona como uma classe utilitária global.
extends RefCounted
class_name DamageTypes

## Dano físico.
##
## Usado por ataques corporais, lâminas, impactos e golpes físicos.
const PHYSICAL: String = "physical"

## Dano mágico.
##
## Usado pela parte mágica da arma híbrida da Gaia e por magias futuras.
const MAGICAL: String = "magical"

## Dano elemental de fogo.
##
## Planejado para armas, inimigos, artefatos ou efeitos futuros.
const FIRE: String = "fire"

## Dano elemental de gelo.
const ICE: String = "ice"

## Dano elemental de raio/eletricidade.
const LIGHTNING: String = "lightning"

## Dano de veneno.
const POISON: String = "poison"

## Dano verdadeiro.
##
## Normalmente usado para dano que ignora defesa, resistência ou reduções,
## dependendo da regra implementada no DamageResolver.
const TRUE_DAMAGE: String = "true_damage"

## Verifica se uma string representa um tipo de dano válido.
##
## Usado para validar resources e evitar que erros de digitação em strings
## quebrem cálculos de dano, fraqueza ou resistência.
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
