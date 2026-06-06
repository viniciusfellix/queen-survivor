# Lifecycle — Hitbox e Hurtbox

## Gaia atingindo Goblin

```text
WeaponDefinition.attack_areas
→ GaiaInitialWeaponController instancia DirectionalAttackHitbox
→ rectangle runtime é criada
→ detecta HurtboxComponent do EnemyBase
→ envia components physical + magical
→ EnemyBase/DamageResolver
```

Uma execução da hitbox não deve reaplicar dano ao mesmo receiver repetidamente.

## Goblin atingindo Gaia

```text
EnemyDefinition.contact_attack
→ EnemyAttackDefinition
→ EnemyAttackHitbox cria shape runtime
→ aguarda delay inicial
→ detecta PlayerHurtbox
→ respeita cooldown por receiver
→ PlayerController/DamageResolver
```

## Segurança

- Gaia morta desativa PlayerHurtbox.
- Goblin morto desativa Hurtbox e ContactAttackHitbox.
- A pausa nativa (`get_tree().paused`) impede efeitos durante level-up/encerramento: hitboxes e hurtboxes pausáveis param de processar sozinhas.
- Alterações de shape durante física devem usar operação segura/deferred quando aplicável.
