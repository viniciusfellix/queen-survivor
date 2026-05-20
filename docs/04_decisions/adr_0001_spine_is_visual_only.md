# ADR 0001 — Spine é camada visual, não gameplay

## Status

Aceita.

## Contexto

O projeto Queen Survivors usa Godot com integração Spine. A primeira personagem jogável é Gaia.

O Spine é responsável por exibir animações e estados visuais, mas não deve controlar as regras de gameplay.

## Decisão

A lógica de gameplay não acessa o SpineSprite diretamente.

O fluxo correto é:

InputManager
→ PlayerController
→ PlayerRuntimeState
→ GaiaVisualController
→ GaiaSpineAdapter
→ SpineSprite

## Consequências

- O gameplay pode evoluir sem depender da API do Spine.
- Mudanças futuras no plugin Spine devem afetar apenas os adapters visuais.
- A animação representa o estado do jogo, mas não decide o estado do jogo.
- Ataque, dano, morte, movimento e cooldown serão controlados por sistemas de gameplay, não por eventos obrigatórios de animação.

## Aplicação no Módulo 1

A cena PlayerGaia instancia GaiaVisual.

GaiaVisual contém o SpineSprite e o GaiaSpineAdapter.

PlayerController nunca chama SpineSprite diretamente.
