extends Resource
class_name MapDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

# 10 minutos oficiais = 600 segundos.
@export var duration_seconds: float = 600.0

# Fórmula oficial de vitória:
# dinheiro_final = (moedas_coletadas × victory_multiplier) + victory_bonus
@export var victory_multiplier: float = 2.0
@export var victory_bonus: int = 0

# Timeline de spawn do mapa.
@export var spawn_timeline: SpawnTimelineDefinition

func is_valid_definition() -> bool:
	return id.strip_edges() != "" and duration_seconds > 0.0
