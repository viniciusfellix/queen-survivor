# Domínio — Inimigos

## Conteúdo atual

O Goblin perseguidor básico é configurado por `enemy_chaser_basic.tres`.

## `EnemyBase`

`class_name EnemyBase`. Responsável por aplicar definition, perseguir Gaia, configurar hitbox/hurtbox, receber dano (via cast tipado, sem `has_method`/`call`), acionar feedback, emitir recompensas e morrer.

É **poolizado**: a morte devolve o inimigo ao `PoolManager` com `PoolManager.despawn(self)` em vez de `queue_free`, e o reset de estado acontece em `_on_pool_acquire()` ao ser reutilizado.

## Definition

`EnemyDefinition` contém atributos, `contact_attack`, fraquezas/resistências, XP/moeda, hurtboxes e visual.

## Goblin validado

| Regra | Valor |
|---|---|
| Fraquezas | `physical`, `magical` |
| Bônus | `50%` |
| Hurtbox | capsule `21/80`, offset `(0,0)` |
| Ataque | physical raw `6`, intervalo `1.0`, delay `0.75` |
| Shape ofensiva | capsule `25/88`, offset `(0,2)` |

O flash claro ocorre ao receber dano e é somente feedback visual.
