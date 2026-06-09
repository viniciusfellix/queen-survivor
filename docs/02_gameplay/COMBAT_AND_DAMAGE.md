# Combat And Damage

## Fundacao atual

- `BodyCollision` nao causa dano
- `Hitbox` e `Hurtbox` usam `Area2D`
- `DamagePayload` transporta dados do golpe
- `DamageResolver` concentra a regra matematica

## Damage Model V2

Regra oficial atual:

1. `base_damage` sempre aplica
2. componentes fisico/magico sao bonus condicionais
3. bonus so aplica quando o alvo e fraco ao tipo
4. resistencia e neutralidade nao aplicam bonus
5. resistencia nao reduz `base_damage`
6. fraqueza nao multiplica `base_damage`

## Fluxo de dano atual

```text
DirectionalAttackHitbox
-> HurtboxComponent
-> EnemyBase.receive_damage()
-> DamageResolver
```

```text
EnemyAttackHitbox
-> PlayerHurtbox
-> PlayerController.receive_damage()
-> DamageResolver
```

## Feedback visual

- Gaia: sequencia vermelho -> preto -> vermelho -> normal
- Enemy: sequencia clara configuravel -> normal -> clara -> normal
- feedback visual nao altera dano
