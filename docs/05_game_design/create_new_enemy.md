# Como criar um novo inimigo

## 1. Criar dados do inimigo

Duplicar:

```txt
res://data/enemies/enemy_chaser_basic.tres
```

Renomear, por exemplo:

```txt
res://data/enemies/enemy_fast_goblin.tres
```

Alterar:

```txt
id = enemy_fast_goblin
display_name_key = enemy.fast_goblin.name
description_key = enemy.fast_goblin.description
```

## 2. Ajustar atributos

Campos comuns:

```txt
base_max_hp
base_move_speed
contact_damage
xp_reward
coin_drop_chance
coin_drop_value
weak_damage_types
resistant_damage_types
```

## 3. Adicionar textos

No:

```txt
res://data/localization/pt_br.json
```

Adicionar:

```json
"enemy.fast_goblin.name": "Goblin Veloz",
"enemy.fast_goblin.description": "Um goblin mais rápido e frágil."
```

## 4. Usar no spawner

Abrir:

```txt
res://gameplay/spawners/EnemySpawner.tscn
```

Trocar:

```txt
enemy_definition
```

para o novo `.tres`.

## 5. Visual

Se for usar o mesmo visual do goblin, não precisa criar nova scene.

Se for novo Spine, criar em:

```txt
res://assets/spine/NOME_DO_INIMIGO/
res://visual/enemies/NOME_DO_INIMIGO/
```
