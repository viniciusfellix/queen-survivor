# Domínio — Drops e Moedas

## Arquivos principais

```txt
definitions/CoinDropDefinition.gd
data/drops/coin_default.tres
gameplay/drops/CoinDrop.gd
gameplay/drops/CoinDrop.tscn
gameplay/drops/DropController.gd
```

## Regra oficial

Moeda é física.

Moeda precisa ser coletada.

Moeda não coletada é perdida no fim da run.

## DropController

Escuta:

```txt
GameEvents.enemy_died
```

E cria `CoinDrop` se a chance passar.

## CoinDrop

Responsável por:

- Ficar no chão.
- Detectar player.
- Ser puxada por magnetismo.
- Emitir coleta.
- Sumir.

## RunController

Escuta:

```txt
GameEvents.run_coin_collected
```

E soma em:

```txt
RunState.run_coins_collected
```
