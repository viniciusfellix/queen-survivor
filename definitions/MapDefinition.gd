## Resource de configuração de mapa/run.
##
## Responsabilidades:
## - definir duração da fase;
## - configurar recompensa de vitória;
## - apontar timeline de spawn;
## - apontar pool de upgrades da run.
##
## Exemplo atual:
## - arena infinita técnica de 10 minutos.
extends Resource
class_name MapDefinition

## ID técnico único do mapa.
@export var id: String = ""

## Chave de localização para nome do mapa.
@export var display_name_key: String = ""

## Chave de localização para descrição do mapa.
@export var description_key: String = ""

## Duração total da run neste mapa, em segundos.
##
## 600 segundos = 10 minutos.
@export var duration_seconds: float = 600.0

## Multiplicador aplicado às moedas coletadas em caso de vitória.
@export var victory_multiplier: float = 2.0

## Bônus fixo adicionado após o multiplicador em caso de vitória.
@export var victory_bonus: int = 0

## Timeline que define quais inimigos nascem em cada faixa de tempo.
@export var spawn_timeline: SpawnTimelineDefinition

## Pool de upgrades disponível neste mapa/run.
@export var upgrade_pool: UpgradePoolDefinition

## Verifica se o mapa possui configuração mínima válida.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and duration_seconds > 0.0
