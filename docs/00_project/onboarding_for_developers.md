# Onboarding para Desenvolvedores

## Princípio central

O projeto é um survivor-like em Godot com visuais Spine. A regra principal é: **gameplay decide; visual representa**. Scripts Spine não calculam dano, XP, recompensa, progressão ou colisão ofensiva.

## Primeira leitura

Leia `docs/README.md`, o status do módulo, a arquitetura de cenas, a arquitetura de combate, os lifecycles e o índice de responsabilidades.

## Cena técnica

Use `res://scenes/run/RunScene.tscn` como composição oficial atual da run.

`res://gameplay/test/TestGaiaScene.tscn` permanece no projeto apenas como referência técnica temporária da composição anterior.

## Antes de alterar

- Descubra o domínio responsável pela regra.
- Para balanceamento, edite resource antes de editar script.
- Nunca use `BodyCollision` como dano.
- Não duplique definitions em cena genérica e resource de conteúdo.
- Não crie signals especulativos sem fluxo real.
- Não copie lógica já extraída para bases/helpers.

## Antes de concluir

- Ative apenas logs necessários.
- Valide shapes com `Debug > Visible Collision Shapes`.
- Faça busca por nomes removidos se renomeou um sistema.
- Execute regressão.
- Comente funções novas/alteradas.
- Atualize documentação e ADRs.
