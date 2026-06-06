## Catálogo central de estados gerais de gameplay/entidade.
##
## Responsabilidades:
## - padronizar nomes de estados;
## - evitar strings soltas em PlayerController, inimigos, visuais e UI;
## - facilitar integração entre gameplay e camada visual.
##
## Observação:
## Nem todos os estados precisam ser usados por todos os personagens.
## Eles servem como vocabulário comum para sistemas que precisam representar
## estado atual de uma entidade.
extends RefCounted
class_name GameplayStateTypes

## Estado parado/ocioso.
const IDLE: String = "idle"

## Estado de movimento normal.
const MOVING: String = "moving"

## Estado de ataque.
const ATTACKING: String = "attacking"

## Estado de dash/esquiva.
const DASHING: String = "dashing"

## Estado de impacto/dano recebido.
const HIT: String = "hit"

## Estado morto/derrotado.
const DEAD: String = "dead"

## Estado de level-up.
##
## Pode ser usado para bloquear gameplay ou indicar que a run está aguardando
## escolha de upgrade.
const LEVEL_UP: String = "level_up"

## Estado de pausa.
const PAUSED: String = "paused"
