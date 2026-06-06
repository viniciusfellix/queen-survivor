## Catálogo central dos canais de log técnico do projeto.
##
## Responsabilidades:
## - padronizar os canais usados pelo DeveloperAuditLogger;
## - evitar strings divergentes em scripts diferentes;
## - permitir listar todos os canais disponíveis para debug, UI técnica
##   ou configuração de logs.
##
## Este arquivo não registra logs diretamente.
## Ele apenas define os nomes oficiais dos canais.
extends RefCounted
class_name DeveloperLogChannels

## Lifecycle geral da aplicação.
##
## Exemplos:
## - boot;
## - inicialização de autoloads;
## - carregamento principal.
const LIFECYCLE: String = "LIFECYCLE"

## Eventos relacionados a cenas.
##
## Exemplos:
## - cena carregada;
## - player instanciado;
## - roots configurados.
const SCENE: String = "SCENE"

## Eventos de spawn.
##
## Exemplos:
## - wave ativa;
## - inimigo criado;
## - moeda/drop criado.
const SPAWN: String = "SPAWN"

## Eventos de combate.
##
## Exemplos:
## - hitbox atingiu hurtbox;
## - dano calculado;
## - inimigo recebeu dano;
## - player recebeu dano.
const COMBAT: String = "COMBAT"

## Eventos visuais/animações.
##
## Exemplos:
## - animação Spine trocada;
## - overlay executado;
## - flip visual atualizado.
const ANIMATION: String = "ANIMATION"

## Eventos de upgrades.
##
## Exemplos:
## - upgrade escolhido;
## - upgrade aplicado;
## - stat temporário alterado.
const UPGRADE: String = "UPGRADE"

## Eventos de save.
##
## Exemplos:
## - save carregado;
## - save criado;
## - resultado persistido;
## - progressão resetada.
const SAVE: String = "SAVE"

## Eventos de interface.
##
## Exemplos:
## - painel aberto;
## - HUD atualizada;
## - resultado exibido.
const UI: String = "UI"

## Eventos relacionados a signals.
##
## Útil para investigar emissão/consumo de eventos globais.
const SIGNAL: String = "SIGNAL"

## Eventos de auditoria técnica.
##
## Exemplos:
## - canal habilitado;
## - limpeza executada;
## - validação estrutural.
const AUDIT: String = "AUDIT"

## Retorna todos os canais oficiais de log.
##
## Usado pelo DeveloperAuditLogger para validar canais e por ferramentas
## técnicas para exibir lista/resumo de canais disponíveis.
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
