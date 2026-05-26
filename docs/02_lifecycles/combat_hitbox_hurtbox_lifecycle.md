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
- `RunQuery.is_gameplay_blocked()` impede efeitos após encerramento.
- Alterações de shape durante física devem usar operação segura/deferred quando aplicável.
