# Lifecycle — Coin Drop

```text
EnemyBase morre
→ GameEvents.enemy_died
→ DropController avalia chance
→ CoinDrop nasce em DropRoot
→ idle inicial / magnetismo
→ coleta física
→ run_coin_collected + run_coins_changed
→ RunState soma moeda
```

Moeda não é concedida ao matar; ela precisa ser coletada. Moeda não coletada não entra no resultado final.
