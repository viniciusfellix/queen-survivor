# ADR 0006 — Arma da Gaia usa componentes de dano

## Status

Aceita.

## Decisão

A arma inicial da Gaia não usa string única `hybrid`.

Ela usa componentes:

```txt
physical
magical
```

## Consequência

Fraquezas e resistências são calculadas por componente.

Se o inimigo for fraco aos dois, ambos os bônus são aplicados.
