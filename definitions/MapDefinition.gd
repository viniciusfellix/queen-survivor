## Resource de configuração de um mapa jogável.
##
## Este arquivo deve ser editado pelo game designer para configurar:
## - identificação e textos do mapa;
## - duração da run;
## - recompensa de vitória;
## - timeline de inimigos;
## - pool de upgrades disponível.
extends Resource
class_name MapDefinition

## ID técnico único do mapa.
##
## Exemplo atual: `map_test_arena_10min`.
@export var id: String = ""

## Chave de localização utilizada para exibir o nome do mapa.
@export var display_name_key: String = ""

## Chave de localização utilizada para exibir a descrição do mapa.
@export var description_key: String = ""

## Duração total da run em segundos.
##
## Regra oficial do primeiro mapa: 10 minutos, equivalentes a 600 segundos.
@export var duration_seconds: float = 600.0

## Multiplicador aplicado às moedas coletadas quando a run termina em vitória.
##
## Fórmula oficial:
## dinheiro_final = (moedas_coletadas × victory_multiplier) + victory_bonus
@export var victory_multiplier: float = 2.0

## Bônus fixo adicional entregue somente em vitória.
@export var victory_bonus: int = 0

## Timeline que define quais inimigos aparecem ao longo do tempo.
@export var spawn_timeline: SpawnTimelineDefinition

## Pool de upgrades disponível nos level-ups deste mapa.
##
## No protótipo atual, o mapa define a pool ativa.
## Futuramente a seleção poderá combinar mapa, Queen e progressão global.
@export var upgrade_pool: UpgradePoolDefinition

## Verifica se o mapa possui os dados mínimos para iniciar uma run.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and duration_seconds > 0.0
