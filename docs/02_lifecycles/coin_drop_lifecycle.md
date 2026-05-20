# Lifecycle — Moedas e Magnetismo

## Drop

```txt
EnemyBase morre
↓
GameEvents.enemy_died carrega coin_drop_chance e coin_drop_value
↓
DropController rola chance
↓
CoinDrop é instanciado em DropRoot
```

## Estado no chão

A moeda fica no chão e não conta como coletada.

## Magnetismo

```txt
CoinDrop detecta player dentro de magnet_radius
↓
velocity move_toward player
↓
moeda é puxada
```

## Coleta

```txt
distância até player <= collect_radius
↓
GameEvents.run_coin_collected
↓
RunController.add_coins()
↓
RunState.run_coins_collected aumenta
```

## Regra oficial

Moeda não coletada é perdida no final da run.

## Diferença para XP

```txt
XP: direta
Moeda: física
```
