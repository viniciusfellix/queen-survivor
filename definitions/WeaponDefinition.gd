## Resource de configuração base de uma arma.
##
## Para balanceamento da arma inicial da Gaia, este arquivo controla:
## - cooldown;
## - cena e posição do visual do ataque;
## - cena, raio e duração da hitbox;
## - componentes de dano físico/mágico;
## - limite futuro de nível da arma.
extends Resource
class_name WeaponDefinition

## ID técnico único da arma.
##
## Exemplo atual: `gaia_initial_weapon`.
@export var id: String = ""

## Chave de localização utilizada para nome da arma.
@export var display_name_key: String = ""

## Chave de localização utilizada para descrição da arma.
@export var description_key: String = ""

## Nível máximo planejado para a arma durante a run.
##
## A regra oficial atual define armas com limite máximo de nível 10.
@export var max_level: int = 10

## Intervalo inicial, em segundos, entre ataques consecutivos.
@export var cooldown_seconds: float = 2.0

## Distância entre a Queen e o visual instanciado do ataque.
@export var attack_visual_offset: float = 86.0

## Tempo de existência do visual do ataque antes de desaparecer.
@export var attack_visual_lifetime: float = 0.22

## Cena visual utilizada ao disparar a arma.
##
## Pode conter placeholder temporário ou visual Spine futuro.
@export_file("*.tscn") var attack_visual_scene_path: String = ""

## Cena da hitbox utilizada para aplicar dano do ataque.
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

## Distância entre a Queen e o centro da hitbox criada no ataque.
@export var attack_hitbox_offset: float = 86.0

## Raio base da área de acerto do ataque.
@export var attack_hitbox_radius: float = 72.0

## Tempo base durante o qual a hitbox permanece ativa.
@export var attack_hitbox_lifetime: float = 0.12

## Modelo oficial atual de dano composto.
##
## Uma arma pode possuir um ou mais componentes.
## Exemplo da Gaia: dano físico + dano mágico no mesmo ataque.
@export var damage_components: Array[DamageComponentDefinition] = []

## Dano utilizado por armas simples sem componentes cadastrados.
##
## Quando `damage_components` estiver preenchido, a lista de componentes
## prevalece sobre este fallback.
@export var base_damage: int = 5

## Tipo utilizado junto ao dano fallback de armas simples.
@export var damage_type: String = DamageTypes.PHYSICAL

## Verifica se a arma possui um ID técnico válido.
func is_valid_definition() -> bool:
	return id.strip_edges() != ""

## Informa se a arma utiliza o modelo composto de dano.
func has_damage_components() -> bool:
	return not damage_components.is_empty()
