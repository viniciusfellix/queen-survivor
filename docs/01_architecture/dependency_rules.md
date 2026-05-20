# Regras de Dependência

## Regra 1 — Gameplay não depende de Spine

Correto:

```txt
EnemyBase
→ GoblinWarriorVisualController
→ GoblinWarriorSpineAdapter
→ SpineSprite
```

Errado:

```txt
EnemyBase
→ SpineSprite diretamente
```

## Regra 2 — Data não conhece runtime

Resources `.tres` não devem guardar estado vivo da partida.

## Regra 3 — Runtime não é save

`RunState` morre no fim da run. Ele não é progresso permanente.

## Regra 4 — Visual não aplica dano

Visual pode tocar animação, trocar sprite, esconder placeholder, mas não decide dano.

## Regra 5 — UI não recalcula regra

UI apenas exibe ou envia escolha do jogador.

Exemplo:

`LevelUpPanel` emite a escolha, mas quem aplica o upgrade é o `RunController` e o `PlayerController`.

## Regra 6 — Event Bus para sistemas cruzados

Quando um evento afeta múltiplos sistemas, use `GameEvents`.

Exemplo:

`enemy_died` afeta:

- XP.
- Kills.
- Drops.
- Futuro histórico.
- Futuro resultado.
