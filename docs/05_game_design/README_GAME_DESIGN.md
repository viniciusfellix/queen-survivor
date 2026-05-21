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

### Mapa, duração e recompensa de vitória

```txt
res://data/maps/map_test_arena_10min.tres

Resultado da run

A tela está em:

res://ui/result/ResultPanel.tscn

Mas o game designer normalmente não precisa editar essa tela para balanceamento.


Adicione também esta seção:

```md
## Resultado e recompensa

O resultado usa as moedas realmente coletadas na run.

Moedas que ficaram no chão não entram no resultado.

A recompensa final segue:

```txt
Vitória:
dinheiro_final = (moedas_coletadas × victory_multiplier) + victory_bonus

Derrota:
dinheiro_final = moedas_coletadas

Para editar multiplicador e bônus de vitória, use:

res://data/maps/map_test_arena_10min.tres

---

# 7. Atualizar `docs/05_game_design/where_to_edit_balance.md`

Adicione esta seção:

```md
## Duração do mapa

Arquivo:

```txt
res://data/maps/map_test_arena_10min.tres

Campo:

duration_seconds

Valores úteis:

30    # teste rápido
60    # teste médio
600   # valor oficial de 10 minutos
Multiplicador de vitória

Arquivo:

res://data/maps/map_test_arena_10min.tres

Campo:

victory_multiplier

Exemplo:

2.0

Se o jogador coletar 10 moedas e vencer:

10 × 2.0 = 20
Bônus de vitória

Arquivo:

res://data/maps/map_test_arena_10min.tres

Campo:

victory_bonus

Exemplo:

victory_bonus = 5

Se o jogador coletar 10 moedas, multiplicador for 2 e bônus for 5:

final_money_reward = (10 × 2) + 5
final_money_reward = 25
Recompensa na derrota

Não existe multiplicador na derrota.

final_money_reward = moedas_coletadas

---


## Regra importante

Se é número de balanceamento, quase sempre está em `res://data/`.

Se é visual/animação, está em `res://visual/` ou `res://assets/`.

Se é código, está em `res://gameplay/`, `res://runtime/`, `res://definitions/`.
