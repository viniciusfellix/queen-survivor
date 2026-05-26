# Editar o Goblin Básico

## Resources

```text
enemy_chaser_basic.tres
hurtbox_area_enemy_chaser_basic_body.tres
enemy_attack_chaser_basic_contact.tres
attack_area_enemy_chaser_basic_contact.tres
```

## Fraqueza atual

```text
Weak Damage Types: physical, magical
Weakness Bonus Percent: 50.0
```

O ataque base da Gaia (`3+3`) deve causar `10` dano final.

## Hurtbox atual

```text
Capsule radius=21 height=80 offset=(0,0)
```

## Ataque atual

```text
Raw Damage=6; physical; interval=1.0; delay=0.75
Capsule radius=25 height=88 offset=(0,2)
```

## Feedback

O clarão do Goblin ao receber dano é visual e configurado pelo controller visual; não é parâmetro de balanceamento de combate.
