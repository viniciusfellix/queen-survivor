# PR3 Debug Root Separation

## Objetivo da PR

Esta PR separa explicitamente as ferramentas técnicas e debug-only em um node `DebugRoot`, sem alterar gameplay, sem remover ferramentas e sem mudar o fluxo oficial de runtime.

## O que esta PR faz

- cria `DebugRoot` em cenas de composição de run;
- move para dentro desse root apenas nodes claramente técnicos/debug-only;
- mantém `DebugOverlay` e `PrototypeToolsPanel` funcionando como antes;
- não altera lógica de gameplay;
- não altera o boot oficial do jogo.

## Nodes movidos para `DebugRoot`

### `gameplay/test/TestGaiaScene.tscn`

- `DebugOverlay`
- `PrototypeToolsPanel`

### `scenes/run/RunScene.tscn`

- `DebugOverlay`
- `PrototypeToolsPanel`

## O que esta PR não faz

- não remove nenhuma ferramenta técnica;
- não cria modo dev/build separation;
- não altera `Main.gd`;
- não torna `RunScene` a cena oficial;
- não altera scripts de gameplay;
- não altera recursos `.tres` funcionais;
- não muda combate, player, moeda, spawn, level-up, resultado ou save.

## Natureza da mudança

`DebugRoot` é apenas uma organização arquitetural da árvore de cena.

Ele existe para:

- deixar explícito o que é técnico/dev-only;
- preparar futuras PRs de separação de debug para builds sem ferramentas;
- reduzir a mistura visual entre UI de jogo e UI técnica na composição das cenas.

## Cenas alteradas

- `gameplay/test/TestGaiaScene.tscn`
- `scenes/run/RunScene.tscn`

## Fluxo oficial de runtime

Continua inalterado.

A cena oficial atual continua sendo:

- `res://gameplay/test/TestGaiaScene.tscn`

`RunScene` continua sendo apenas a cena paralela criada na PR2.

## Testes manuais

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Abrir `gameplay/test/TestGaiaScene.tscn`.
4. Confirmar que `DebugRoot` existe.
5. Confirmar que `DebugOverlay` está presente dentro de `DebugRoot`.
6. Confirmar que `PrototypeToolsPanel` está presente dentro de `DebugRoot`.
7. Rodar a cena oficial atual via `Main` / `TestGaiaScene`.
8. Confirmar:
   - Gaia move;
   - dash funciona;
   - ataque funciona;
   - Goblin spawna;
   - Goblin persegue;
   - Goblin causa dano;
   - moeda dropa;
   - moeda é coletada;
   - HUD aparece;
   - level-up funciona;
   - resultado funciona.
9. Testar `F3`:
   - `PrototypeToolsPanel` abre/fecha.
10. Testar `F4`:
   - `RuntimeTreeSnapshot` continua funcionando, se já funcionava antes.
11. Testar `DebugOverlay`:
   - overlay aparece quando habilitado;
   - dados continuam sendo exibidos.
12. Abrir `scenes/run/RunScene.tscn`.
13. Confirmar que `RunScene` abre sem referências quebradas.
14. Confirmar console sem erro novo.

## Riscos conhecidos

- embora o reparent seja simples, sempre existe risco de alguma ferramenta depender implicitamente do parent atual;
- esta PR não altera scripts para acomodar isso, por decisão deliberada de baixo risco;
- `RunScene` ainda é paralela e pode não ter sido validada manualmente no editor antes desta reorganização.

## Próximos passos esperados

1. validar manualmente que as ferramentas continuam funcionando após o reparent;
2. manter `DebugRoot` apenas como organização estrutural por enquanto;
3. numa PR futura, avaliar carregamento condicional de debug/dev-only;
4. numa PR futura, consolidar `RunScene` como composition root oficial quando o runtime paralelo estiver maduro.
