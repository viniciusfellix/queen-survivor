# ADR 0001 — Spine é camada visual, não gameplay

## Status

Aceita.

## Contexto

O projeto usa Godot com integração Spine para Gaia, goblin e futuros ataques.

## Decisão

A lógica de gameplay não acessa `SpineSprite` diretamente.

Fluxo correto:

```txt
Gameplay
→ VisualController
→ SpineAdapter
→ SpineSprite
```

## Consequências

- Trocas no plugin Spine afetam apenas adapters.
- A animação não decide dano.
- A animação não decide morte.
- A animação não decide cooldown.
