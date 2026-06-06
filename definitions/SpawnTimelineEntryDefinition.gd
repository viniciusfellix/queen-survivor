## Resource que define uma entrada/faixa de spawn dentro de uma timeline.
##
## Responsabilidades:
## - determinar quando a entrada está ativa;
## - informar qual cena de inimigo instanciar;
## - informar qual EnemyDefinition aplicar;
## - configurar intervalo de spawn;
## - limitar quantidade de inimigos vivos;
## - configurar distância mínima e máxima de nascimento.
extends Resource
class_name SpawnTimelineEntryDefinition

## ID técnico único desta entrada de spawn.
@export var id: String = ""

## Tempo inicial, em segundos, em que esta entrada fica ativa.
@export var start_time_seconds: float = 0.0

## Tempo final, em segundos, em que esta entrada deixa de estar ativa.
@export var end_time_seconds: float = 60.0

## Cena genérica do inimigo que será instanciada.
##
## Normalmente deve apontar para EnemyBase.tscn.
@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"

## Definition que configura o inimigo instanciado.
##
## Exemplo:
## - enemy_chaser_basic.tres.
@export var enemy_definition: EnemyDefinition

## Intervalo entre tentativas de spawn.
@export var spawn_interval_seconds: float = 2.2

## Limite máximo de inimigos vivos desta entrada.
@export var max_alive_enemies: int = 12

## Distância mínima do player para criar o inimigo.
@export var spawn_min_distance: float = 420.0

## Distância máxima do player para criar o inimigo.
@export var spawn_max_distance: float = 620.0

## Se true, cria inimigo imediatamente ao ativar a entry.
@export var spawn_on_activate: bool = true

## Verifica se a entrada possui configuração mínima válida.
func is_valid_entry() -> bool:
	return (
		id.strip_edges() != ""
		and end_time_seconds > start_time_seconds
		and spawn_interval_seconds > 0.0
		and max_alive_enemies > 0
		and enemy_scene_path.strip_edges() != ""
		and enemy_definition != null
	)

## Verifica se esta entrada está ativa no tempo informado.
func is_active_at(elapsed_seconds: float) -> bool:
	return elapsed_seconds >= start_time_seconds and elapsed_seconds < end_time_seconds
