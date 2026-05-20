# Resources, Runtime e Save

## Definitions

Classes Resource que definem o formato dos dados.

Exemplos:

- `EnemyDefinition`
- `WeaponDefinition`
- `UpgradeDefinition`
- `CoinDropDefinition`

## Data

Arquivos `.tres` configuráveis.

Exemplos:

- `enemy_chaser_basic.tres`
- `weapon_gaia_initial.tres`
- `coin_default.tres`

## Runtime

Estado vivo temporário.

Exemplos:

- `RunState`
- `PlayerRuntimeState`

## Save

Estado permanente do jogador.

Ainda será expandido.

## Regra fundamental

Não confundir:

```txt
Definition/Data = configuração
Runtime = estado vivo da partida
Save = progresso permanente
```

## Exemplo

`weapon_gaia_initial.tres` diz:

```txt
cooldown base = 2.0
dano físico = 3
dano mágico = 3
```

Durante a run, um upgrade pode transformar em:

```txt
cooldown atual = 1.8
dano físico atual = 4
dano mágico atual = 4
```

Esse valor alterado não deve editar o `.tres` original. Por isso os componentes da arma são duplicados em runtime.
