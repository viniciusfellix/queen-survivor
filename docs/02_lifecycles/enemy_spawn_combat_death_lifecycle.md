### Spawn, combate e morte com pool

O inimigo é poolizado de ponta a ponta:

1. `EnemySpawner` obtém a instância via `PoolManager.spawn` (reusa da fila ou cria nova);
2. a posição é aplicada **antes** do `add_child` (o nó não nasce na origem 0,0);
3. `_on_pool_acquire()` reseta o estado da instância reusada e `setup()` reaplica a `EnemyDefinition`;
4. durante a run, combate via `EnemyAttackHitbox` / Hurtbox;
5. ao morrer, em vez de `queue_free`, o inimigo chama `PoolManager.despawn(self)` (volta à fila, fora da árvore).

### Ciclo de movimento e impacto do Goblin

Durante cada frame físico:

1. atualiza velocidades externas de esbarrão e knockback;
2. calcula perseguição direta à Gaia;
3. reduz a perseguição se estiver sob knockback;
4. soma impulsos externos;
5. executa `move_and_slide()`;
6. processa colisões corporais com outros inimigos;
7. atualiza o visual usando a direção de perseguição.

Não há mais checagem de bloqueio da run por frame; a pausa é nativa (`get_tree().paused`).

O dano não é aplicado por colisão corporal. O ataque do Goblin permanece em `EnemyAttackHitbox`.
