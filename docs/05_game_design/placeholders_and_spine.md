# Placeholders e Spine

## Regra

A lógica da arma/personagem/inimigo não deve depender do tipo visual.

Pode ser:

- PNG placeholder.
- Spine final.
- Sprite temporário.
- Debug shape.

## Ataque da Gaia

PNG atual:

```txt
res://assets/placeholders/weapons/gaia_initial_weapon/gaia_attack_placeholder.png
```

Scene visual:

```txt
res://visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn
```

## Como trocar o placeholder

1. Substituir PNG no mesmo caminho; ou
2. Alterar `Sprite2D.texture` em `GaiaAttackVisual.tscn`.

## Como preparar Spine futuro

Criar:

```txt
res://assets/spine/weapons/gaia_initial_weapon/
```

Adicionar:

```txt
.atlas
.png
.skel
.tres skeleton data
```

Depois criar/adaptar:

```txt
GaiaAttackSpineAdapter.gd
```

E usar `SpineRoot`.

## Inimigo

Visual do goblin:

```txt
res://visual/enemies/goblin_warrior/GoblinWarriorVisual.tscn
```

Animações atuais:

```txt
Idle
Run
Die
```

## Queen

Visual da Gaia:

```txt
res://visual/characters/gaia/GaiaVisual.tscn
```

Animações atuais:

```txt
Idle1_Pose2
Run1_Pose3
Die_Pose1
Dash1_Pose3
Blink_Idle_Pose2
Ultimate1_Pose1
```
