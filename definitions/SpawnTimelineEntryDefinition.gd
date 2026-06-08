## Resource que define uma entrada/faixa de spawn dentro de uma timeline.
##
## Responsabilidades:
## - determinar quando a wave pode ficar ativa;
## - suportar range de inicio/fim com fallback legacy;
## - agrupar regras individuais de spawn;
## - manter compatibilidade com resources antigos de um unico inimigo.
extends Resource
class_name SpawnTimelineEntryDefinition

## ID tecnico unico desta entrada de spawn.
@export var id: String = ""

## Nome/alias estavel da wave para design e debug.
@export var wave_name: String = ""

## Tempo inicial legacy, em segundos, em que esta entrada fica ativa.
@export var start_time_seconds: float = 0.0

## Tempo final legacy, em segundos, em que esta entrada deixa de estar ativa.
@export var end_time_seconds: float = 60.0

## Faixa aleatoria opcional de inicio da wave.
##
## Valores negativos mantem fallback para start_time_seconds.
@export var start_time_min_seconds: float = -1.0
@export var start_time_max_seconds: float = -1.0

## Faixa aleatoria opcional de termino da wave.
##
## Valores negativos mantem fallback para end_time_seconds.
@export var end_time_min_seconds: float = -1.0
@export var end_time_max_seconds: float = -1.0

## Se true, esta wave pode coexistir com outras waves ativas.
@export var allow_concurrent: bool = false

## Cena generica legacy do inimigo que sera instanciado.
##
## Mantida para compatibilidade com resources antigos.
@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"

## Definition legacy que configura o inimigo instanciado.
@export var enemy_definition: EnemyDefinition

## Intervalo legacy entre tentativas de spawn.
@export var spawn_interval_seconds: float = 2.2

## Limite legacy de inimigos vivos desta entrada.
@export var max_alive_enemies: int = 12

## Distancia minima do player para criar o inimigo.
@export var spawn_min_distance: float = 420.0

## Distancia maxima do player para criar o inimigo.
@export var spawn_max_distance: float = 620.0

## Se true, cria inimigo imediatamente ao ativar a entry.
@export var spawn_on_activate: bool = true

## Regras individuais de spawn desta wave.
##
## Quando vazio, a entry cai no modo legacy e usa enemy_scene_path/enemy_definition.
@export var spawn_rules: Array[SpawnRuleDefinition] = []

func is_valid_entry() -> bool:
	return (
		id.strip_edges() != ""
		and get_effective_end_time_max_seconds() > get_effective_start_time_min_seconds()
		and spawn_interval_seconds > 0.0
		and max_alive_enemies > 0
		and (
			has_spawn_rules()
			or (
				enemy_scene_path.strip_edges() != ""
				and enemy_definition != null
			)
		)
	)

func is_active_at(elapsed_seconds: float) -> bool:
	return (
		elapsed_seconds >= get_effective_start_time_min_seconds()
		and elapsed_seconds < get_effective_end_time_max_seconds()
	)

func has_spawn_rules() -> bool:
	for spawn_rule: SpawnRuleDefinition in spawn_rules:
		if spawn_rule == null:
			continue

		if spawn_rule.is_valid_definition():
			return true

	return false

func get_effective_spawn_rules() -> Array[SpawnRuleDefinition]:
	var valid_rules: Array[SpawnRuleDefinition] = []

	for spawn_rule: SpawnRuleDefinition in spawn_rules:
		if spawn_rule == null:
			continue

		if not spawn_rule.is_valid_definition():
			continue

		valid_rules.append(spawn_rule)

	if not valid_rules.is_empty():
		return valid_rules

	var legacy_rule: SpawnRuleDefinition = build_legacy_spawn_rule()

	if legacy_rule != null and legacy_rule.is_valid_definition():
		valid_rules.append(legacy_rule)

	return valid_rules

func build_legacy_spawn_rule() -> SpawnRuleDefinition:
	if enemy_scene_path.strip_edges() == "" or enemy_definition == null:
		return null

	var legacy_rule: SpawnRuleDefinition = SpawnRuleDefinition.new()
	legacy_rule.id = "%s_legacy_rule" % id
	legacy_rule.enemy_scene_path = enemy_scene_path
	legacy_rule.enemy_definition = enemy_definition
	legacy_rule.spawn_probability_percent = 100.0
	legacy_rule.spawn_interval_min_seconds = spawn_interval_seconds
	legacy_rule.spawn_interval_max_seconds = spawn_interval_seconds
	legacy_rule.max_total_spawns = 0
	legacy_rule.max_alive = 0
	legacy_rule.active_from_seconds = 0.0
	legacy_rule.active_until_seconds = -1.0
	legacy_rule.spawn_on_activate = spawn_on_activate
	legacy_rule.tags = PackedStringArray(["legacy"])

	return legacy_rule

func should_rule_spawn_on_activate(rule: SpawnRuleDefinition) -> bool:
	if rule == null:
		return false

	if has_spawn_rules():
		return rule.spawn_on_activate

	return spawn_on_activate

func get_effective_start_time_min_seconds() -> float:
	if start_time_min_seconds >= 0.0:
		return start_time_min_seconds

	return start_time_seconds

func get_effective_start_time_max_seconds() -> float:
	if start_time_max_seconds >= 0.0:
		return max(get_effective_start_time_min_seconds(), start_time_max_seconds)

	return get_effective_start_time_min_seconds()

func get_effective_end_time_min_seconds() -> float:
	if end_time_min_seconds >= 0.0:
		return max(get_effective_start_time_min_seconds(), end_time_min_seconds)

	return max(get_effective_start_time_min_seconds(), end_time_seconds)

func get_effective_end_time_max_seconds() -> float:
	if end_time_max_seconds >= 0.0:
		return max(get_effective_end_time_min_seconds(), end_time_max_seconds)

	return get_effective_end_time_min_seconds()
