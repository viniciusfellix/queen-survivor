# Domínio — Combate e Dano

## Arquivos principais

```txt
gameplay/combat/DamagePayload.gd
gameplay/combat/DamageResolver.gd
definitions/DamageComponentDefinition.gd
core/constants/DamageTypes.gd
```

## Dano no player

Usa:

```gdscript
DamageResolver.calculate_received_damage(raw_damage, defense_percent)
```

Fórmula:

```txt
Dano recebido = Dano inimigo - (Dano inimigo × Defesa × 0,01)
```

Dano mínimo:

```txt
1
```

## Dano em inimigos

Usa:

```gdscript
DamageResolver.calculate_enemy_damage(payload, enemy_definition)
```

## Dano por componentes

A arma da Gaia usa:

```txt
physical 3
magical 3
```

Cada componente pode sofrer:

- Fraqueza.
- Resistência.

## Fraqueza

Se inimigo for fraco ao tipo:

```txt
final = raw × (1 + weakness_bonus_percent/100)
```

## Resistência

Se inimigo for resistente ao tipo:

```txt
final = raw × (1 - resistance_reduction_percent/100)
```

## Exemplo

Gaia:

```txt
physical 3
magical 3
```

Goblin fraco aos dois, bônus 50%:

```txt
physical 3 -> 5
magical 3 -> 5
total 10
```
