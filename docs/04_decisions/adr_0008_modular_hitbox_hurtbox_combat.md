# ADR 0008 — Combate Modular por Hitbox e Hurtbox

## Status

Aceita e validada após regressão do Módulo 1.

## Problema

A hitbox circular original da Gaia não representava sua meia elipse visual. O dano de contato por distância do Goblin não escalaria para inimigos, bosses ou ataques com formatos distintos.

## Decisão

Separar definitivamente:

- `BodyCollision`: física corporal;
- `Hitbox`: área ofensiva;
- `Hurtbox`: área vulnerável.

Introduzir resources/classes:

- `CombatShapeDefinition`;
- `AttackAreaDefinition`;
- `HurtboxAreaDefinition`;
- `HurtboxComponent`;
- `EnemyAttackDefinition`;
- `EnemyAttackHitbox`.

## Fluxos oficiais

```text
PlayerAttackHitbox → EnemyHurtbox → EnemyBase
EnemyAttackHitbox → PlayerHurtbox → PlayerController
```

## Benefícios

- game designer edita shapes sem alterar código;
- novas armas/inimigos podem possuir formatos distintos;
- ataques deixam de depender de body collision;
- o debug mostra shapes reais;
- projéteis e bosses podem reutilizar o modelo.

## Conceitos removidos

Não recriar: `attack_hitbox_radius`, `hit_radius`, `weapon_hitbox_radius_flat`, `contact_damage_radius`, dano por distância manual ou `contains_local_point` para o sistema atual.
