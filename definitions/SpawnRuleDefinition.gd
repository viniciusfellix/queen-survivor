## Resource que define uma regra individual de spawn dentro de uma wave.
##
## Responsabilidades:
## - apontar cena e EnemyDefinition do inimigo a nascer;
## - controlar probabilidade por tentativa;
## - controlar intervalo min/max entre tentativas;
## - limitar total de spawns e, opcionalmente, vivos simultaneos;
## - permitir janela interna relativa ao inicio da wave;
## - classificar a regra por tags, como normal, elite ou boss.
extends Resource
class_name SpawnRuleDefinition

## ID tecnico unico da regra dentro da wave.
@export var id: String = ""

## Permite desligar a regra sem remover o resource.
@export var enabled: bool = true

## Cena generica do inimigo que sera instanciada.
@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"

## Definition que sera aplicada no EnemyBase instanciado.
@export var enemy_definition: EnemyDefinition

## Probabilidade, em percentual, de um spawn acontecer a cada tentativa.
@export_range(0.0, 100.0, 0.1) var spawn_probability_percent: float = 100.0

## Menor intervalo entre tentativas de spawn desta regra.
@export var spawn_interval_min_seconds: float = 2.2

## Maior intervalo entre tentativas de spawn desta regra.
@export var spawn_interval_max_seconds: float = 2.2

## Limite total de spawns desta regra durante toda a run.
##
## 0 ou negativo = ilimitado.
@export var max_total_spawns: int = 0

## Limite de instancias vivas simultaneas desta regra.
##
## 0 ou negativo = sem limite especifico.
@export var max_alive: int = 0

## Janela interna relativa ao inicio da wave.
@export var active_from_seconds: float = 0.0

## Janela interna relativa ao inicio da wave.
##
## Valor negativo = sem limite superior.
@export var active_until_seconds: float = -1.0

## Se true, tenta spawnar imediatamente quando a regra entra em janela ativa.
@export var spawn_on_activate: bool = false

## Tags semanticas para design/debug.
@export var tags: PackedStringArray = []

func is_valid_definition() -> bool:
	return (
		enabled
		and id.strip_edges() != ""
		and enemy_scene_path.strip_edges() != ""
		and enemy_definition != null
		and spawn_interval_min_seconds > 0.0
		and get_effective_spawn_interval_max_seconds() >= get_effective_spawn_interval_min_seconds()
	)

func get_effective_spawn_interval_min_seconds() -> float:
	return max(0.01, spawn_interval_min_seconds)

func get_effective_spawn_interval_max_seconds() -> float:
	return max(
		get_effective_spawn_interval_min_seconds(),
		spawn_interval_max_seconds
	)

func get_effective_active_from_seconds() -> float:
	return max(0.0, active_from_seconds)

func get_effective_active_until_seconds() -> float:
	if active_until_seconds < 0.0:
		return -1.0

	return max(get_effective_active_from_seconds(), active_until_seconds)

func is_active_for_wave_elapsed(wave_elapsed_seconds: float) -> bool:
	if wave_elapsed_seconds < get_effective_active_from_seconds():
		return false

	var effective_until_seconds: float = get_effective_active_until_seconds()

	if effective_until_seconds >= 0.0 and wave_elapsed_seconds >= effective_until_seconds:
		return false

	return true

func has_tag(tag_name: String) -> bool:
	return tags.has(tag_name)
