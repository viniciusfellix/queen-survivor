# Lifecycle — Goblin / EnemyBase

## Criação

```text
EnemySpawner seleciona SpawnTimelineEntryDefinition
→ instancia EnemyBase
→ setup(enemy_definition, player)
→ EnemyBase lê enemy_chaser_basic.tres
→ configura Hurtbox e ContactAttackHitbox
→ visual inicia idle/run
```

## Perseguição

O Goblin atual move-se diretamente em direção à Gaia. A evolução futura para formação orgânica ao redor da Queen não deve alterar os contratos de ataque/hurtbox.

## Ataque

```text
ContactAttackHitbox
→ detecta PlayerHurtbox
→ respeita start_delay_seconds e hit_interval_seconds
→ cria DamagePayload physical
→ PlayerController.receive_damage
```

O antigo dano por distância manual não existe mais.

## Dano e morte

```text
DirectionalAttackHitbox detecta Hurtbox
→ EnemyBase.receive_damage
→ DamageResolver processa fraquezas
→ flash claro
→ se HP zerar: desativa hurtbox e attack hitbox, emite reward, toca death e agenda remoção
```
