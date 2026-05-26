## Catálogo central dos canais disponíveis no sistema de auditoria técnica.
##
## Os canais permitem ativar logs por domínio sem poluir o console durante
## testes comuns da run. Scripts de gameplay não devem declarar canais livres;
## devem utilizar uma das constantes centralizadas neste arquivo.
extends RefCounted
class_name DeveloperLogChannels

## Eventos gerais do ciclo de vida: boot, início/fim de run e transições globais.
const LIFECYCLE: String = "LIFECYCLE"

## Carregamento de cenas, instanciação estrutural e resolução de nodes principais.
const SCENE: String = "SCENE"

## Geração de inimigos, waves, drops e coleta de moedas.
const SPAWN: String = "SPAWN"

## Acertos, dano causado/recebido, morte e interações de combate.
const COMBAT: String = "COMBAT"

## Troca de animações, adapters Spine e estados visuais.
const ANIMATION: String = "ANIMATION"

## Level-up, escolha de opções e aplicação de melhorias durante a run.
const UPGRADE: String = "UPGRADE"

## Leitura, escrita, reset e aplicação de resultados no save permanente.
const SAVE: String = "SAVE"

## HUD, painéis, feedbacks visuais e ferramentas de interface.
const UI: String = "UI"

## Auditoria específica de emissões/conexões de signals, quando necessária.
const SIGNAL: String = "SIGNAL"

## Ações manuais de diagnóstico, como exportação runtime e ferramentas técnicas.
const AUDIT: String = "AUDIT"

## Retorna todos os canais válidos do logger.
##
## Esta lista é utilizada pelo DeveloperAuditLogger para validar ativações
## manuais de canais durante testes técnicos.
static func get_all_channels() -> Array[String]:
	return [
		LIFECYCLE,
		SCENE,
		SPAWN,
		COMBAT,
		ANIMATION,
		UPGRADE,
		SAVE,
		UI,
		SIGNAL,
		AUDIT,
	]
