## Resource de configuração base de uma Queen jogável.
##
## Este arquivo representa dados editáveis da personagem:
## - identificação;
## - atributos iniciais;
## - arma inicial;
## - áreas vulneráveis utilizadas para receber ataques;
## - cena visual;
## - resource Spine correspondente;
## - dash configurável.
##
## Comportamentos especiais exclusivos de futuras Queens deverão ser
## adicionados de forma configurável quando suas regras forem implementadas.
extends Resource
class_name QueenDefinition

## ID técnico único da Queen.
##
## Exemplo atual: `gaia`.
@export var id: String = ""

## Chave de localização utilizada para exibir o nome da Queen.
@export var display_name_key: String = ""

## Chave de localização utilizada para exibir a descrição da Queen.
@export var description_key: String = ""

@export_group("Base Attributes")

## Vida máxima inicial da Queen no começo da run.
@export var base_max_hp: int = 100

## Velocidade inicial de movimento da Queen.
@export var base_move_speed: float = 180.0

@export_group("Starting Equipment")

## ID técnico da arma equipada ao iniciar a run.
@export var starting_weapon_id: String = ""

@export_group("Hurtbox")

## Áreas vulneráveis que podem receber ataques inimigos.
##
## Estas shapes não substituem a BodyCollision responsável por movimento.
@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

@export_group("Visual")

## Caminho da cena visual que representa a Queen em gameplay.
@export_file("*.tscn") var visual_scene_path: String = ""

## Caminho do resource Spine utilizado pelo visual real da Queen.
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

@export_group("Dash")

## Configuração de dash desta Queen.
##
## Cada Queen poderá ter distância, duração, cooldown, área de impacto
## e knockback próprios.
@export var dash_definition: QueenDashDefinition

## Verifica se a Queen possui os dados mínimos exigidos pelo protótipo.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and visual_scene_path.strip_edges() != ""
	)

## Indica se existe ao menos uma área vulnerável válida cadastrada.
func has_valid_hurtbox_areas() -> bool:
	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		if hurtbox_area.is_valid_definition():
			return true

	return false
