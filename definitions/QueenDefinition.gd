## Resource principal de configuração de uma Queen jogável.
##
## Responsabilidades:
## - definir atributos base;
## - indicar arma inicial;
## - configurar hurtbox;
## - configurar visual;
## - configurar dash.
##
## Exemplo atual:
## - queen_gaia.tres.
extends Resource
class_name QueenDefinition

## ID técnico único da Queen.
@export var id: String = ""

## Chave de localização para nome exibido.
@export var display_name_key: String = ""

## Chave de localização para descrição.
@export var description_key: String = ""

@export_group("Base Attributes")

## HP máximo base da Queen.
@export var base_max_hp: int = 100

## Velocidade base de movimento.
@export var base_move_speed: float = 180.0

@export_group("Starting Equipment")

## ID técnico da arma inicial.
##
## O sistema de arma deve resolver esse ID para o WeaponDefinition correto.
@export var starting_weapon_id: String = ""

@export_group("Hurtbox")

## Áreas vulneráveis da Queen.
##
## EnemyAttackHitbox detecta PlayerHurtbox construída a partir dessas áreas.
@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

@export_group("Visual")

## Cena visual da Queen.
@export_file("*.tscn") var visual_scene_path: String = ""

## Resource de skeleton Spine, se utilizado.
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

@export_group("Dash")

## Configuração de dash desta Queen.
##
## Permite que cada Queen tenha regras próprias de dash no futuro.
@export var dash_definition: QueenDashDefinition

## Verifica se a Queen possui configuração mínima válida.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and visual_scene_path.strip_edges() != ""
	)

## Verifica se existe pelo menos uma hurtbox válida.
func has_valid_hurtbox_areas() -> bool:
	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		if hurtbox_area.is_valid_definition():
			return true

	return false
