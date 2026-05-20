# ADR 0003 — Aim Direction não controla o facing visual

## Status

Aceita.

## Decisão

A Gaia possui:

- `aim_direction`: mira/ataque.
- `facing_direction`: lado visual do corpo.

O corpo da Gaia vira pelo movimento horizontal.

A arma usa `aim_direction`.

## Consequência

O jogador pode andar para um lado e atacar para outro.
