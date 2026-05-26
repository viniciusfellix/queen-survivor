## Resource de uma faixa temporal de spawn.
##
## Este é o arquivo editável pelo game designer para definir uma wave/faixa:
## - quando começa e termina;
## - qual inimigo será criado;
## - frequência de criação;
## - limite de inimigos vivos;
## - distância de nascimento em relação ao player;
## - criação imediata ao ativar a faixa.
extends Resource
class_name SpawnTimelineEntryDefinition

## ID técnico único desta faixa da timeline.
##
## Exemplo: `wave_00_intro`.
@export var id: String = ""

## Segundo da run em que esta faixa começa a valer.
@export var start_time_seconds: float = 0.0

## Segundo da run em que esta faixa deixa de valer.
@export var end_time_seconds: float = 60.0

## Cena base que será instanciada para cada inimigo desta faixa.
@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"

## Definition que fornece atributos, dano, fraquezas, XP e drop do inimigo.
@export var enemy_definition: EnemyDefinition

## Intervalo, em segundos, entre tentativas de spawn desta faixa.
@export var spawn_interval_seconds: float = 2.2

## Quantidade máxima de inimigos simultaneamente vivos permitida nesta faixa.
@export var max_alive_enemies: int = 12

## Distância mínima do player em que o inimigo pode nascer.
##
## Ajuda a impedir spawn colado na Queen no início ou durante a run.
@export var spawn_min_distance: float = 420.0

## Distância máxima do player em que o inimigo pode nascer.
@export var spawn_max_distance: float = 620.0

## Define se, ao entrar nesta faixa, o spawner tenta criar
## imediatamente um primeiro inimigo sem aguardar o intervalo completo.
@export var spawn_on_activate: bool = true

## Verifica se a faixa possui todos os dados mínimos necessários ao spawn.
func is_valid_entry() -> bool:
	return (
		id.strip_edges() != ""
		and end_time_seconds > start_time_seconds
		and spawn_interval_seconds > 0.0
		and max_alive_enemies > 0
		and enemy_scene_path.strip_edges() != ""
		and enemy_definition != null
	)

## Informa se esta faixa deve estar ativa no instante atual da run.
##
## O limite final é exclusivo: uma faixa deixa de valer exatamente
## quando `elapsed_seconds` alcança `end_time_seconds`.
func is_active_at(elapsed_seconds: float) -> bool:
	return elapsed_seconds >= start_time_seconds and elapsed_seconds < end_time_seconds
