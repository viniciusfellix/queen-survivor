# Como editar o Goblin

Arquivo principal:

```txt
res://data/enemies/enemy_chaser_basic.tres
```

## Campos principais

### HP

```txt
base_max_hp
```

Quanto maior, mais ataques a Gaia precisa para matar.

### Velocidade

```txt
base_move_speed
```

Define a velocidade com que o goblin persegue Gaia.

### Dano de contato

```txt
contact_damage
```

Dano bruto aplicado quando encosta na Gaia.

### Raio de contato

```txt
contact_damage_radius
```

Se parecer que o goblin encosta e não causa dano, aumente esse valor.

Valor atual recomendado:

```txt
64
```

### Intervalo de contato

```txt
contact_damage_interval_seconds
```

Tempo entre um dano e outro enquanto está encostado.

### XP

```txt
xp_reward
```

XP direta dada ao morrer.

### Moeda

```txt
coin_drop_chance
coin_drop_value
```

Exemplos:

```txt
coin_drop_chance = 1.0   # 100%
coin_drop_chance = 0.25  # 25%
coin_drop_value = 1
```

## Fraquezas

Campo:

```txt
weak_damage_types
```

Valores possíveis atuais:

```txt
physical
magical
```

Se adicionar os dois:

```txt
physical
magical
```

A Gaia aplica bônus nos dois componentes.

## Resistências

Campo:

```txt
resistant_damage_types
```

Exemplo:

```txt
magical
```

Reduz dano mágico.

## Bônus/redução

```txt
weakness_bonus_percent = 50
resistance_reduction_percent = 50
```

Com 50%, dano 3 vira aproximadamente 5 em fraqueza e 2 em resistência.
