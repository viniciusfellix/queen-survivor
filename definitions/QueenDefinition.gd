## Resource de configuração base de uma Queen jogável.
##
## Este arquivo representa dados editáveis da personagem:
## - identificação;
## - atributos iniciais;
## - arma inicial;
## - cena visual;
## - resource Spine correspondente.
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

## Vida máxima inicial da Queen no começo da run.
@export var base_max_hp: int = 100

## Velocidade inicial de movimento da Queen.
@export var base_move_speed: float = 180.0

## ID técnico da arma equipada ao iniciar a run.
@export var starting_weapon_id: String = ""

## Caminho da cena visual que representa a Queen em gameplay.
@export_file("*.tscn") var visual_scene_path: String = ""

## Caminho do resource Spine utilizado pelo visual real da Queen.
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

## Verifica se a Queen possui os dados mínimos exigidos pelo protótipo.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and visual_scene_path.strip_edges() != ""
	)
