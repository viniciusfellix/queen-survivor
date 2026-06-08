# PR4 Promote RunScene

## Objetivo da PR

Promover `res://scenes/run/RunScene.tscn` para ser a cena oficial de runtime da run, substituindo a dependência direta de `res://gameplay/test/TestGaiaScene.tscn` no boot do jogo.

## Qual cena era carregada antes

Antes desta PR, o jogo carregava:

- `res://gameplay/test/TestGaiaScene.tscn`

via:

- `res://scenes/Main.tscn`
- `res://scenes/Main.gd`

## Qual cena passa a ser carregada agora

Após esta PR, o jogo passa a carregar:

- `res://scenes/run/RunScene.tscn`

via o mesmo fluxo de boot:

- `res://scenes/Main.tscn`
- `res://scenes/Main.gd`

## O que esta PR não faz

- não remove `TestGaiaScene`;
- não altera lógica de gameplay;
- não altera scripts de gameplay;
- não altera resources `.tres` funcionais;
- não altera sistemas de combate, moeda, dash, save, upgrade, UI ou debug;
- não muda o boot para outra raiz além da `RunScene`.

## Estado de `TestGaiaScene`

`res://gameplay/test/TestGaiaScene.tscn` continua existindo no projeto como cena técnica antiga/de referência.

Ela não foi removida nesta PR.

## Papel de `RunScene`

`RunScene` passa a ser a composition root oficial da run.

Isso significa apenas que:

- o boot oficial passa a apontar para ela;
- a composição já preparada nas PRs anteriores agora assume o papel de runtime oficial.

## Arquivos alterados

- `scenes/Main.gd`
- `docs/migration/CURRENT_SOURCE_OF_TRUTH.md`

## Arquivos criados

- `docs/migration/PR4_PROMOTE_RUNSCENE.md`

## Por que esta PR não altera gameplay

Porque a mudança foi limitada ao ponto de entrada do boot:

- o jogo continua usando os mesmos scripts de gameplay;
- os mesmos resources funcionais;
- os mesmos componentes internos de player, inimigos, run, HUD, drops e debug.

Em outras palavras, o que muda é:

- qual cena de composição é carregada primeiro.

O que não muda é:

- a lógica interna dos sistemas.

## Testes manuais necessários

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar o jogo pelo botão principal / play.
4. Confirmar que a cena carregada agora é `RunScene`.
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
   - `DebugOverlay` continua disponível;
   - `PrototypeToolsPanel` continua funcionando com `F3`;
   - `RuntimeTreeSnapshot` continua funcionando com `F4`, se já funcionava antes;
   - vitória funciona;
   - derrota funciona;
   - `ResultPanel` aparece;
   - save continua funcionando.
6. Abrir `res://gameplay/test/TestGaiaScene.tscn` manualmente.
7. Confirmar que ela ainda existe sem referência quebrada.
8. Confirmar console sem erro novo.

## Riscos conhecidos

- como `RunScene` foi promovida sem refatorar gameplay, qualquer diferença estrutural remanescente entre ela e `TestGaiaScene` pode aparecer agora no boot oficial;
- esta PR assume que a cena paralela criada na PR2 está suficientemente equivalente à composição anterior.

## Próximos passos esperados

1. validar manualmente `RunScene` como nova source of truth oficial;
2. manter `TestGaiaScene` como cena técnica/de referência por enquanto;
3. seguir a migração arquitetural sobre `RunScene` nas próximas PRs;
4. decidir em PR futura quando `TestGaiaScene` pode deixar de existir.
