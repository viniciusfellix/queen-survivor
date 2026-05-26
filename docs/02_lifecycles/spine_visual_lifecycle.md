# Lifecycle — Spine e Feedback Visual

Spine é camada de apresentação. Gameplay define estado; controllers visuais o representam.

## Gaia

```text
PlayerRuntimeState → GaiaVisualController → SpineVisualControllerBase → GaiaSpineAdapter → SpineSprite
```

A Gaia pisca vermelho quando sofre dano.

## Goblin

```text
EnemyBase → GoblinWarriorVisualController → SpineVisualControllerBase → GoblinWarriorSpineAdapter → SpineSprite
```

O Goblin executa clarão branco/intenso breve ao receber dano. O flash não altera a regra de movimento, ataque ou morte.

## Bases reutilizáveis

- `SpineAnimationAdapterBase`: resolve sprite e animações.
- `SpineVisualControllerBase`: resolve adapter, evita animação repetida e aplica flip.
