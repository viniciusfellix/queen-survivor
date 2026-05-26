# Game Design — Shapes, Hitboxes e Hurtboxes

## Conceitos

- **BodyCollision:** corpo físico; não altera alcance de dano.
- **Hitbox:** região que causa dano.
- **Hurtbox:** região que recebe dano.

## Gaia — área ofensiva da arma inicial

Resource: `attack_area_gaia_initial_primary.tres`.

```text
Shape: RectangleShape2D
Size: Vector2(90, 300)
Local Offset: Vector2(0, 0)
Weapon Attack Hitbox Offset: 160
```

Para ampliar alcance, altere o tamanho da rectangle ou use o upgrade de escala; não volte a criar raio circular.

## Goblin — hurtbox

Resource: `hurtbox_area_enemy_chaser_basic_body.tres`.

```text
CapsuleShape2D
Radius: 21
Height: 80
Local Offset: Vector2(0, 0)
```

## Goblin — ataque corporal

Resources: `enemy_attack_chaser_basic_contact.tres` e `attack_area_enemy_chaser_basic_contact.tres`.

```text
Raw Damage: 6
Damage Type: physical
Hit Interval Seconds: 1.0
Start Delay Seconds: 0.75
Shape: CapsuleShape2D
Radius: 25
Height: 88
Local Offset: Vector2(0, 2)
```

## Gaia — hurtbox

Resource: `hurtbox_area_gaia_body.tres`.

```text
CapsuleShape2D
Radius: 23
Height: 102
Local Offset: Vector2(0, 41)
```

## Como testar

Ative `Debug > Visible Collision Shapes`. Shapes devem cobrir a região pretendida com justiça. Ajuste size/radius/height para escala e offset apenas para posicionamento. Nunca duplique definitions em nodes genéricos.
