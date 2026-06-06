# Lifecycle — Goblin / EnemyBase

## Criação

```text
EnemySpawner seleciona SpawnTimelineEntryDefinition
→ PoolManager.spawn (reusa instância da fila ou cria nova)
→ posição aplicada antes do add_child
→ _on_pool_acquire reseta o estado da instância reusada
→ setup(enemy_definition, player)
→ EnemyBase lê enemy_chaser_basic.tres
→ configura Hurtbox e ContactAttackHitbox
→ visual inicia idle/run
```

O `EnemySpawner` pré-aquece o pool no `_ready` (`prewarm_pool_count`, default 24). Instâncias inativas ficam fora da árvore.

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
→ se HP zerar: desativa hurtbox e attack hitbox, emite reward, sai do grupo `enemy`, toca death e agenda remoção
```

Ao zerar HP, `die()` desativa as áreas, emite `enemy_died`, sai do grupo `enemy` e, após `remove_after_death_seconds`, chama `PoolManager.despawn(self)` (não `queue_free`). Quando a instância é readquirida do pool, `_on_pool_acquire()` restaura vida, grupo e velocidades e reativa as áreas; o `setup()` reaplica a `EnemyDefinition`.
