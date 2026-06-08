# PR5 RunScene Source Of Truth

## Objetivo

Consolidar `res://scenes/run/RunScene.tscn` como source of truth oficial da run e remover ambiguidade documental sobre a antiga `res://gameplay/test/TestGaiaScene.tscn`.

## Por que `RunScene` virou source of truth

Depois da PR4, o boot oficial do jogo passou a carregar:

- `res://scenes/run/RunScene.tscn`

Isso faz de `RunScene` a composition root oficial atual da run, mesmo reaproveitando os mesmos sistemas de gameplay já existentes.

## Por que `TestGaiaScene` ainda não será removida

`TestGaiaScene` continua útil como referência técnica temporária porque:

- preserva a composição anterior para comparação;
- reduz risco durante a migração gradual;
- ainda pode ajudar em inspeções manuais e checagens estruturais.

Esta PR não remove, não move e não altera a cena `.tscn` legada.

## Arquivos que passam a ser a referência para composição

Mudanças futuras de composição da run devem ser feitas primeiro em:

- `res://scenes/run/RunScene.tscn`
- `res://scenes/run/RunScene.gd`

## Arquivos que devem ser evitados para novas mudanças de composição

Evitar iniciar novas mudanças de composição da run em:

- `res://gameplay/test/TestGaiaScene.tscn`
- `res://gameplay/test/TestGaiaScene.gd`

Esses arquivos permanecem apenas como referência técnica temporária até uma PR futura de remoção ou arquivamento.

## Arquivos alterados nesta PR

- `docs/migration/CURRENT_SOURCE_OF_TRUTH.md`
- `docs/README.md`
- `docs/00_project/onboarding_for_developers.md`
- `docs/01_architecture/scene_architecture.md`
- `docs/02_lifecycles/app_boot_lifecycle.md`
- `gameplay/test/TestGaiaScene.gd` (comentário apenas)
- `scenes/run/RunScene.gd` (comentário apenas)

## O que esta PR não altera

- não altera `Main.gd`;
- não altera nenhuma cena `.tscn`;
- não altera resources `.tres` funcionais;
- não altera gameplay;
- não altera wiring de combate, player, inimigos, drops, save, UI ou debug.

## Testes manuais necessários

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar o jogo pelo botão principal/play.
4. Confirmar que a cena carregada é `RunScene`.
5. Confirmar:
   - Gaia nasce corretamente;
   - câmera segue Gaia;
   - Gaia move;
   - dash funciona;
   - ataque funciona;
   - Goblin spawna;
   - Goblin persegue;
   - Goblin causa dano;
   - Goblin morre;
   - XP entra direto;
   - level-up abre;
   - upgrades funcionam;
   - moeda dropa;
   - moeda é coletada;
   - HUD aparece;
   - DebugOverlay continua disponível;
   - PrototypeToolsPanel continua funcionando com F3;
   - RuntimeTreeSnapshot continua funcionando com F4, se já funcionava antes;
   - vitória funciona;
   - derrota funciona;
   - ResultPanel aparece;
   - save continua funcionando.
6. Abrir `res://gameplay/test/TestGaiaScene.tscn` manualmente e confirmar que ela ainda existe sem referência quebrada.
7. Confirmar console sem erro novo.

## Riscos conhecidos

- ainda existem documentos históricos fora de `docs/migration/` que podem mencionar `TestGaiaScene` em contexto antigo e precisar de revisão pontual futura;
- `TestGaiaScene` continua coexistindo com `RunScene`, então ainda existe risco humano de alguém editar a cena legada por engano se ignorar a documentação.

## Próximos passos esperados

1. manter futuras mudanças de composição concentradas em `RunScene`;
2. seguir a migração arquitetural por domínios pequenos;
3. decidir em PR futura quando `TestGaiaScene` pode ser removida ou arquivada com segurança.
