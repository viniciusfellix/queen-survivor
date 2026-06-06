# Índice Atual de Arquivos — Módulo 1

Para pesquisa rápida detalhada, leia [`06_reference/file_responsibilities.md`](06_reference/file_responsibilities.md).

## Combate modular

```text
definitions/CombatShapeDefinition.gd
definitions/AttackAreaDefinition.gd
definitions/HurtboxAreaDefinition.gd
definitions/EnemyAttackDefinition.gd
gameplay/combat/HurtboxComponent.gd
gameplay/combat/EnemyAttackHitbox.gd
gameplay/weapons/attacks/DirectionalAttackHitbox.gd
```

## Arquivos alterados pela migração

```text
definitions/QueenDefinition.gd
definitions/EnemyDefinition.gd
definitions/WeaponDefinition.gd
definitions/UpgradeTypes.gd
gameplay/player/PlayerController.gd
gameplay/enemies/EnemyBase.gd
gameplay/weapons/gaia/GaiaInitialWeaponController.gd
visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd
```

## Infraestrutura atual

```text
autoloads/PoolManager.gd            (novo: pool central de objetos)
data/localization/translation.csv   (tradução nativa, 7 locales)
```

Removidos: `autoloads/LocalizationManager.gd` e `data/localization/pt_br.json` (localização migrou para tradução nativa do Godot).

## Referências adicionais

- Resources atuais: `06_reference/current_resources_index.md`.
- Debug/audit: `07_debug_audit/README_DEBUG_AUDIT.md`.
- Regressão: `08_testing/regression_module_1.md`.
