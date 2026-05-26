## Catálogo central de estados lógicos e visuais de entidades.
##
## Atualmente utilizado principalmente pela Gaia e por seus controllers
## de animação. Estados reservados permitem evolução futura sem espalhar
## strings manuais pelo projeto.
extends RefCounted
class_name GameplayStateTypes

## Entidade viva e parada.
const IDLE: String = "idle"

## Entidade em deslocamento normal.
const MOVING: String = "moving"

## Estado reservado para execução explícita de ataque.
const ATTACKING: String = "attacking"

## Estado reservado para dash/rolagem.
const DASHING: String = "dashing"

## Estado reservado para reação específica a impacto.
const HIT: String = "hit"

## Entidade morta ou derrotada.
const DEAD: String = "dead"

## Estado reservado para bloqueio durante escolha de melhoria.
const LEVEL_UP: String = "level_up"

## Estado reservado para pausa geral de gameplay.
const PAUSED: String = "paused"
