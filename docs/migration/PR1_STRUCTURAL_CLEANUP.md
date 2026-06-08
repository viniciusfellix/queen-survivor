# PR1 Structural Cleanup

## Objetivo

Esta PR faz uma limpeza estrutural mínima para iniciar a migração arquitetural do projeto sem alterar runtime, gameplay ou conteúdo funcional.

## Escopo desta PR

- remover arquivos temporários `.tmp` versionados pelo editor Godot;
- adicionar regras ao `.gitignore` para evitar novos temporários semelhantes;
- registrar a source of truth atual do runtime e dos resources principais;
- não alterar scripts `.gd`;
- não alterar cenas `.tscn` funcionais;
- não alterar resources `.tres` funcionais.

## O que esta PR remove

- `gameplay/test/TestGaiaScene.tscn6158799705.tmp`
- `gameplay/test/TestGaiaScene.tscn6275747883.tmp`
- `gameplay/test/TestGaiaScene.tscn6283063278.tmp`
- `gameplay/player/PlayerGaia.tscn16296637380.tmp`
- `gameplay/player/PlayerGaia.tscn2451716848.tmp`

## O que esta PR adiciona

- `.gitignore`
- `docs/migration/PR1_STRUCTURAL_CLEANUP.md`
- `docs/migration/CURRENT_SOURCE_OF_TRUTH.md`

## O que esta PR não faz

- não cria `RunScene`;
- não separa `DebugRoot`;
- não move `DebugOverlay` ou `PrototypeToolsPanel`;
- não remove a duplicidade de attack area da Gaia;
- não altera `Main.gd`;
- não altera `TestGaiaScene.tscn`;
- não altera `PlayerGaia.tscn`;
- não altera definições de arma, queen, inimigo ou mapa;
- não altera combate, dano, moeda, upgrades, run, save ou HUD.

## Justificativa

Antes de qualquer refatoração arquitetural, a base precisa ficar:

- sem resíduos óbvios do editor;
- com regras básicas de versionamento mais seguras;
- com a source of truth atual documentada.

Isso reduz ruído e evita que próximas PRs misturem limpeza estrutural com mudança de comportamento.

## Impacto esperado

Nenhum impacto de runtime.

Os arquivos removidos não participam do fluxo oficial do projeto. Esta PR só:

- limpa artefatos temporários;
- melhora higiene de repositório;
- documenta o estado atual.
