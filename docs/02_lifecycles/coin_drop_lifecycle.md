# Lifecycle — Coin Drop

```text
EnemyBase morre
→ GameEvents.enemy_died
→ DropController avalia chance
→ PoolManager.spawn da CoinDrop em DropRoot (posição antes do add_child)
→ _on_pool_acquire reseta o estado da moeda reusada
→ idle inicial / magnetismo
→ coleta física
→ run_coin_collected + run_coins_changed
→ RunState soma moeda
→ PoolManager.despawn(self) (não queue_free)
```

A moeda é poolizada: nasce via `PoolManager.spawn` e, na coleta, chama `PoolManager.despawn(self)` em vez de `queue_free`; ao ser reusada, `_on_pool_acquire()` reseta seu estado.

Moeda não é concedida ao matar; ela precisa ser coletada. Moeda não coletada não entra no resultado final.
