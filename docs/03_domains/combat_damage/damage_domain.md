# Domínio — Combate e Dano

## Responsabilidades

Este domínio define payloads, componentes, formas, hitboxes/hurtboxes e resolução de defesa/fraquezas/resistências.

## Arquivos centrais

| Arquivo | Responsabilidade |
|---|---|
| `CombatShapeDefinition.gd` | geometria configurável base |
| `AttackAreaDefinition.gd` | área ofensiva semântica |
| `HurtboxAreaDefinition.gd` | área vulnerável semântica |
| `DamageComponentDefinition.gd` | componente tipado |
| `DamagePayload.gd` | transporte de dano/fonte |
| `DamageResolver.gd` | resolução determinística |
| `HurtboxComponent.gd` | construção runtime de hurtboxes |
| `DirectionalAttackHitbox.gd` | ataque de arma contra EnemyHurtbox |
| `EnemyAttackDefinition.gd` | dados de ataque inimigo |
| `EnemyAttackHitbox.gd` | ataque inimigo contra PlayerHurtbox |

## Gaia contra Goblin

A arma base possui `physical:3` e `magical:3`. O Goblin atual é fraco a ambos com 50% de bônus:

```text
physical: round(3 × 1.5) = 5
magical:  round(3 × 1.5) = 5
final_total = 10
```

## Goblin contra Gaia

O ataque corporal envia dano físico bruto 6, redutível por defesa. O `PlayerController` resolve defesa e assegura dano mínimo válido conforme implementação atual.

## Invariantes

- Dano só ocorre entre hitbox e hurtbox compatíveis.
- `BodyCollision` nunca processa dano.
- Entidade morta desativa regiões relevantes.
- Gameplay bloqueado impede novos efeitos.
