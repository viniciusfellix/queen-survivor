# PR18 - Final Regression and Stress Checklist

## Objetivo

Fechar a rodada atual de migracao arquitetural com um checklist regressivo final e um roteiro minimo de stress test, voltados para QA manual e auditoria externa/manual.

Esta PR e principalmente documental. Ela nao muda gameplay, balanceamento, cena oficial, resources ou scripts funcionais.

## Arquivos criados

- `docs/testing/PR18_FINAL_REGRESSION_STRESS_CHECKLIST.md`
- `docs/migration/PR18_FINAL_REGRESSION_STRESS_CHECKLIST.md`

## Como executar o checklist

1. Abrir o projeto no Godot.
2. Rodar o jogo pelo Play principal.
3. Validar os blocos na ordem do checklist:
   - boot e cena oficial
   - Gaia e camera
   - dash
   - ataque da Gaia
   - inimigos
   - XP, level-up e upgrades
   - moedas
   - resultado e save
   - UI e localizacao
   - debug/dev-only
   - stress test manual
4. Marcar cada item com:
   - `PASS`
   - `FAIL`
   - `BLOCKER`
   - `NEEDS FOLLOW-UP`
   - `NOT TESTED`
5. Registrar observacao, evidencia, sistema afetado e prioridade.

## Areas criticas desta validacao

- `RunScene` como source of truth oficial
- fluxo completo de Gaia -> ataque -> dano -> morte de inimigo
- `EnemyAttackHitbox` -> dano na Gaia -> invulnerabilidade
- XP direta, level-up e aplicacao de upgrades
- moeda fisica com magnetismo e coleta
- pooling de moeda, hitbox, visual, texto e inimigo
- resultado e persistencia
- localizacao nativa ainda exibindo texto corretamente
- debug/dev-only nao poluindo runtime padrao

## O que deve ser tratado como blocker

Considere `BLOCKER` se houver qualquer um destes cenarios:

- projeto abre com missing files
- `RunScene` nao carrega pelo boot principal
- Gaia nao move
- ataque da Gaia nao funciona
- Goblin nao spawna, nao recebe dano ou nao morre
- moeda nao coleta corretamente
- XP/level-up quebra
- save/result falha
- erro recorrente no console durante os testes basicos

## O que pode ficar como pendencia futura

- ruido residual de ergonomia em ferramentas dev-only
- suspeita de custo/performance que nao quebra funcionalmente
- ajustes finos de HUD/debug/localizacao sem impacto em gameplay
- observacoes de stress que precisem profiling mais profundo

## Confirmacao de runtime

Nesta PR nao houve alteracao de runtime:

- nenhum script funcional foi alterado
- nenhuma cena `.tscn` foi alterada
- nenhum resource `.tres` foi alterado
- `project.godot` nao foi alterado
- `Main.gd` nao foi alterado

## Observacao de workspace

Se houver arquivos modificados fora de `docs/`, eles devem ser tratados como preexistentes ou fora do escopo desta PR. Esta PR nao deve versionar `.godot/`.
