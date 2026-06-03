extends Resource
class_name QueenDashDefinition

@export var id: String = ""

@export_group("Movement")

@export var dash_enabled: bool = true

@export var dash_distance_pixels: float = 180.0

@export var dash_duration_seconds: float = 0.18

@export var dash_cooldown_seconds: float = 1.25

@export_group("Impact Knockback")

@export var impact_enabled: bool = true

@export var impact_knockback_pixels: float = 130.0

@export var impact_knockback_duration_seconds: float = 0.18

@export var hit_once_per_enemy: bool = true

@export var impact_source_id: String = "queen_dash"

@export_group("Impact Areas")

@export var impact_areas: Array[AttackAreaDefinition] = []

@export_group("Visual")

@export var dash_animation_name: String = "Dash1_Pose3"

## Define se a Queen pode piscar durante o dash.
##
## A animação específica continua configurada no visual da Queen.
@export var allow_blink_while_dashing: bool = false

## Verifica se a definição possui os dados mínimos para ser usada.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and dash_duration_seconds > 0.0
		and dash_distance_pixels > 0.0
		and dash_cooldown_seconds >= 0.0
	)

## Indica se existe ao menos uma área de impacto válida.
func has_valid_impact_areas() -> bool:
	for impact_area: AttackAreaDefinition in impact_areas:
		if impact_area == null:
			continue

		if impact_area.is_valid_definition():
			return true

	return false
