# Lifecycle - Hitbox e Hurtbox

## Gaia atingindo Goblin

```text
WeaponDefinition.attack_areas
-> GaiaInitialWeaponController
-> DirectionalAttackHitbox <Area2D>
-> HurtboxComponent <Area2D> do inimigo
-> EnemyBase.receive_damage()
-> DamageResolver
```

Uma execucao da hitbox nao deve reaplicar dano ao mesmo receiver pela mesma instancia ativa.

## Goblin atingindo Gaia

```text
EnemyDefinition.contact_attack
-> EnemyAttackHitbox <Area2D>
-> PlayerHurtbox <Area2D>
-> PlayerController.receive_damage()
-> DamageResolver
```

## Estado atual

- Hitboxes e hurtboxes usam `Area2D`, `CollisionShape2D`, layers/masks e signals.
- `BodyCollision` continua separada da fonte de dano.
- `DamageResolver` calcula dano final; nao procura targets nem detecta overlaps.
- Hitboxes temporarias e hitboxes de inimigo ja seguem o contrato modular atual.

## Seguranca

- Gaia morta desativa `PlayerHurtbox`.
- Goblin morto desativa `Hurtbox` e `ContactAttackHitbox`.
- A pausa nativa (`get_tree().paused`) bloqueia processamento de gameplay durante level-up e encerramento.
- Alteracoes de shape/monitoring durante fisica devem usar operacao segura ou deferred quando aplicavel.
