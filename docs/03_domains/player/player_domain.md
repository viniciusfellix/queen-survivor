# Domínio — Player

## Arquivos principais

```txt
gameplay/player/PlayerController.gd
gameplay/player/PlayerGaia.tscn
runtime/PlayerRuntimeState.gd
data/queens/queen_gaia.tres
definitions/QueenDefinition.gd
```

## Responsabilidades

### PlayerController

Executa a entidade viva da Gaia.

Responsável por:

- Entrar no grupo `player`.
- Criar `PlayerRuntimeState`.
- Aplicar `QueenDefinition`.
- Ler input pelo `InputManager`.
- Mover `CharacterBody2D`.
- Receber dano.
- Aplicar upgrades da run.
- Encaminhar upgrades de arma.

### PlayerRuntimeState

Guarda estado vivo:

- HP.
- Defesa.
- Velocidade.
- Direção de movimento.
- Direção de mira.
- Direção visual.
- Estado atual.
- Dano recebido.
- Causa de morte.

### QueenDefinition

Dados base da Gaia:

- ID.
- Nome.
- HP base.
- Velocidade base.
- Arma inicial futura/atual.

## Onde alterar velocidade base da Gaia

Editar:

```txt
res://data/queens/queen_gaia.tres
```

Campo:

```txt
base_move_speed
```

## Onde alterar HP base da Gaia

Editar:

```txt
res://data/queens/queen_gaia.tres
```

Campo:

```txt
base_max_hp
```

## Onde alterar defesa temporária

Editar no node:

```txt
PlayerGaia.tscn
└── PlayerGaia
    └── base_defense_percent
```

Isso é temporário para teste. Futuramente defesa pode vir de artefatos/upgrades.
