# Game Design — Guia para Balanceamento

Esta pasta é para game designers, artistas técnicos e pessoas que vão ajustar números, inimigos, armas, drops e placeholders sem precisar entender todo o código.

## Onde você provavelmente vai mexer

### Goblin

```txt
res://data/enemies/enemy_chaser_basic.tres
```

### Arma da Gaia

```txt
res://data/weapons/weapon_gaia_initial.tres
```

### Dano físico/mágico da Gaia

```txt
res://data/weapons/components/gaia_initial_physical.tres
res://data/weapons/components/gaia_initial_magical.tres
```

### Moeda

```txt
res://data/drops/coin_default.tres
```

### Upgrades do level-up

```txt
res://data/upgrades/
```

### Textos

```txt
res://data/localization/pt_br.json
```

### Placeholder do ataque

```txt
res://assets/placeholders/weapons/gaia_initial_weapon/gaia_attack_placeholder.png
```

### Visual Spine da Gaia

```txt
res://visual/characters/gaia/GaiaVisual.tscn
```

### Visual Spine do Goblin

```txt
res://visual/enemies/goblin_warrior/GoblinWarriorVisual.tscn
```

## Regra importante

Se é número de balanceamento, quase sempre está em `res://data/`.

Se é visual/animação, está em `res://visual/` ou `res://assets/`.

Se é código, está em `res://gameplay/`, `res://runtime/`, `res://definitions/`.
