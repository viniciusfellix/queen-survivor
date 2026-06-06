## Resource principal de configuração de uma arma.
##
## Responsabilidades:
## - definir identificação e textos localizados;
## - configurar cooldown;
## - configurar visual de ataque;
## - configurar hitbox/áreas ofensivas;
## - configurar efeitos pós-hit;
## - configurar dano simples ou composto.
##
## Exemplo atual:
## - weapon_gaia_initial.tres.
##
## Importante:
## Este resource descreve a arma.
## O controller da arma instancia visual, hitbox e aplica upgrades runtime.
extends Resource
class_name WeaponDefinition

## ID técnico único da arma.
@export var id: String = ""

## Chave de localização para nome exibido.
@export var display_name_key: String = ""

## Chave de localização para descrição.
@export var description_key: String = ""

## Nível máximo planejado da arma durante a run.
##
## Regra oficial atual: armas vão até level 10.
@export var max_level: int = 10

## Cooldown base entre ataques.
@export var cooldown_seconds: float = 2.0

@export_group("Attack Visual")

## Distância entre a Queen e o visual instanciado do ataque.
##
## Isso não define área de dano.
## É apenas apresentação visual.
@export var attack_visual_offset: float = 86.0

## Tempo de vida do visual do ataque.
@export var attack_visual_lifetime: float = 0.22

## Cena visual instanciada no disparo da arma.
@export_file("*.tscn") var attack_visual_scene_path: String = ""

@export_group("Attack Hitbox")

## Cena runtime responsável por processar o ataque.
##
## Exemplo atual:
## - DirectionalAttackHitbox.tscn.
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

## Distância frontal da origem da arma até o centro da hitbox.
##
## A hitbox usa AttackAreaDefinition para formas internas,
## mas este offset pode posicionar o conjunto ofensivo em relação à Gaia.
@export var attack_hitbox_offset: float = 86.0

## Tempo de vida da hitbox/área ofensiva.
@export var attack_hitbox_lifetime: float = 0.12

## Áreas ofensivas da arma.
##
## Cada AttackAreaDefinition define uma shape configurável.
## Exemplo atual da Gaia:
## - área retangular/meia-lua aproximada.
@export var attack_areas: Array[AttackAreaDefinition] = []

@export_group("On Hit Effects")

## Habilita knockback quando a arma causa dano válido.
@export var hit_knockback_enabled: bool = false

## Intensidade/distância base do knockback aplicado no inimigo.
@export var hit_knockback_pixels: float = 0.0

## Duração usada para converter knockback em velocidade.
@export var hit_knockback_duration_seconds: float = 0.12

@export_group("Damage")

## Componentes compostos de dano.
##
## Exemplo da Gaia:
## - physical;
## - magical.
##
## Quando preenchido, normalmente prevalece sobre base_damage/damage_type.
@export var damage_components: Array[DamageComponentDefinition] = []

## Dano fallback para armas simples sem damage_components.
@export var base_damage: int = 5

## Tipo de dano fallback para armas simples.
@export var damage_type: String = DamageTypes.PHYSICAL

## Verifica se a arma possui configuração mínima válida.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and has_valid_attack_areas()

## Informa se a arma usa dano composto.
func has_damage_components() -> bool:
	return not damage_components.is_empty()

## Informa se existe pelo menos uma área ofensiva válida.
func has_valid_attack_areas() -> bool:
	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if attack_area.is_valid_definition():
			return true

	return false

## Retorna resumo textual das áreas ofensivas, considerando escala.
##
## Útil para logs, debug e auditoria de upgrades de área.
func get_attack_areas_debug_summary(scale_multiplier: float = 1.0) -> String:
	var summaries: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if not attack_area.is_valid_definition():
			continue

		summaries.append(attack_area.get_debug_summary(scale_multiplier))

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
