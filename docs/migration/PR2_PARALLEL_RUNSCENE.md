# PR2 Parallel RunScene

## Objetivo da PR

Esta PR cria uma cena paralela chamada `RunScene` para preparar a futura migração da composition root oficial da run.

## O que esta PR faz

- cria a pasta `scenes/run/`;
- cria `scenes/run/RunScene.tscn`;
- cria `scenes/run/RunScene.gd`;
- espelha a composição funcional atual de `TestGaiaScene`;
- reutiliza os mesmos scripts, scenes e resources já usados no runtime atual;
- não altera o fluxo oficial carregado por `Main.gd`.

## O que esta PR não faz

- não altera `Main.gd`;
- não troca `initial_scene_path`;
- não altera `gameplay/test/TestGaiaScene.tscn`;
- não altera `gameplay/test/TestGaiaScene.gd`;
- não altera `gameplay/player/PlayerGaia.tscn`;
- não cria `DebugRoot`;
- não remove `DebugOverlay`;
- não remove `PrototypeToolsPanel`;
- não altera combate, moeda, upgrades, input, save ou runtime oficial.

## Situação do runtime após esta PR

`RunScene` ainda **não** é a cena oficial carregada por `Main.gd`.

A source of truth de runtime continua sendo:

- `res://gameplay/test/TestGaiaScene.tscn`

`RunScene` existe apenas para permitir migração gradual em PRs futuras.

## Arquivos criados

- `scenes/run/RunScene.tscn`
- `scenes/run/RunScene.gd`
- `docs/migration/PR2_PARALLEL_RUNSCENE.md`

## Estratégia adotada

A nova cena foi criada como espelho paralelo mínimo da composição atual:

- `ArenaRoot`
- `RuntimeRoot`
- `PlayerRoot`
- `EnemyRoot`
- `DropRoot`
- `SpawnerRoot`
- `EnemySpawner`
- `RunController`
- `DropController`
- `PlayerSpawnPoint`
- `Camera2D`
- `RunHud`
- `RunFeedbackLayer`
- `WorldFeedbackLayer`
- `DebugOverlay`
- `PrototypeToolsPanel`
- `LevelUpPanel`
- `ResultPanel`

O script `RunScene.gd` replica a orquestração atual da cena técnica existente, com:

- nome próprio;
- logs próprios usando fonte `"RunScene"`;
- nenhuma regra nova de gameplay.

## Testes manuais

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar a cena atual do jogo, ainda via `Main` / `TestGaiaScene`.
4. Confirmar:
   - Gaia move;
   - dash funciona;
   - ataque funciona;
   - Goblin spawna;
   - moeda dropa;
   - HUD aparece;
   - level-up funciona;
   - resultado ainda funciona.
5. Abrir `scenes/run/RunScene.tscn` no editor.
6. Confirmar que a cena abre sem referência quebrada.
7. Se possível, executar `RunScene` isoladamente.
8. Confirmar console sem erro novo.

## Riscos conhecidos

- por reutilizar os mesmos componentes do runtime atual, qualquer problema oculto de wiring herdado também aparecerá em `RunScene`;
- esta PR não remove a ambiguidade arquitetural existente entre a cena técnica atual e a futura cena oficial;
- `RunScene` ainda depende da mesma estrutura implícita usada hoje pelo runtime existente.

## Próximos passos esperados

1. validar `RunScene` no editor;
2. manter `TestGaiaScene` como runtime oficial por enquanto;
3. usar `RunScene` como base para futuras PRs de migração gradual;
4. só trocar `Main.gd` quando a cena paralela estiver estável e assumir oficialmente a source of truth de runtime.
