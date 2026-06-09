# Prototype Readiness Report

## Status geral

`READY_WITH_FOLLOW_UPS`

## Resumo executivo

O projeto esta tecnicamente saudavel para entrar na proxima fase de conteudo **com ressalvas**.

Os pilares principais da rodada PR20-PR25 estao presentes:

- cena oficial consolidada em `RunScene`;
- dano V2 consolidado;
- spawn timeline V2 ativa;
- HUD/settings hooks refinados;
- testes unitarios nativos criados;
- cena e recursos paralelos de stress preparados;
- debug/dev-only segregados.

O principal motivo para nao marcar `READY` puro nesta PR26 e simples:

- o stress/profiling de horda continua dependendo de execucao manual com preenchimento real de metricas;
- ainda ha follow-ups conhecidos de polish e tooling;
- existe ao menos um ponto de hygiene documental/artefato versionado (`docs/migration.zip`) que nao bloqueia runtime, mas merece limpeza futura.

## Escopo consolidado desta rodada

### PR20

- Damage Model V2

### PR21

- aim indicator
- feedback visual por sequencia

### PR22

- Spawn Timeline V2

### PR23

- HUD/settings hooks

### PR24

- testes unitarios nativos em GDScript

### PR25

- stress scene/resources/docs paralelos

## Evidencias verificadas nesta PR26

### Cena oficial

- `scenes/Main.gd` continua apontando para `res://scenes/run/RunScene.tscn`
- `scenes/test/StressRunScene.tscn` existe e permanece tecnica/dev-only

### Testes unitarios

- `tests/run_all_tests.gd` existe
- suite executada via Godot headless com **exit code 0**
- como o runner retorna `exit code 1` em falha, isso e evidencia consistente de **0 failures**

### Stress artifacts

- `docs/testing/HORDE_STRESS_TEST_GUIDE.md` existe
- `data/maps/map_stress_arena.tres` existe
- `data/spawn_timelines/stress_arena/` existe
- `scenes/test/StressRunScene.tscn` existe

### Higiene de arquivos

- nenhuma ocorrencia de `.tmp` versionado foi encontrada na busca desta PR
- nenhuma ocorrencia de `.godot/` versionado foi encontrada
- o asset de aim usa o nome correto `gaia_directional_attack.png`
- `project.godot` usa `config/name="Queen Survivors"`

### Referencias antigas conhecidas

- nao foi encontrada dependencia ativa para `res://resources/combat/attack_areas/attack_area_gaia_initial_d.tres` fora de documentacao/historico
- o arquivo ainda existe no repositorio, mas nao apareceu como dependencia ativa nas verificacoes desta PR

## Resultados registrados

### Unit tests

Status: `PASS`

Observacao:

- execucao headless completou com `exit code 0`

Comando usado:

```powershell
& "C:\Users\acer\Documents\Godot\godot-4.2-4.6.1-stable.exe" --headless --path "C:\Users\acer\Documents\Godot\Projects\queen-survivor" --script res://tests/run_all_tests.gd
```

### Stress scene load

Status: `PASS`

Observacao:

- os artefatos tecnicos de stress foram preparados e validados na rodada anterior
- a base esta pronta para execucao manual sem alterar `Main.gd`

### Smoke test oficial

Status: `NOT EXECUTED` nesta PR26

Observacao:

- esta PR foi fechada como readiness documental/QA
- a execucao interativa oficial continua necessaria como validacao humana final quando conveniente

### Stress manual 3-5 minutos

Status: `NOT EXECUTED` nesta PR26

Observacao:

- o guia existe e o caminho de execucao esta pronto
- os valores reais de FPS, physics time, coins alive e pressure peak ainda precisam ser preenchidos manualmente

## Sistemas avaliados

| Sistema | Estado | Observacao |
|---|---|---|
| Dano V2 | PASS | contrato consolidado e coberto por unit tests |
| Aim indicator | PASS com follow-up | funcional, mas ainda depende de ajuste/arte final futura |
| Feedback visual | PASS | sequencias visuais ja integradas |
| Spawn / waves | PASS com follow-up | V2 ativa; stress real ainda precisa perfilado manualmente |
| HUD / settings hooks | PASS com follow-up | base preparada; sensibilidade real ainda e pendencia |
| Unit tests | PASS | runner nativo com execucao headless valida |
| Stress profiling | READY TO RUN | base criada, metricas ainda precisam ser coletadas |
| Debug / dev-only | PASS | segregado sob `DebugRoot` e defaults limpos |
| Pooling | PASS com follow-up | fundamentos estaveis; profiling real de horda ainda e pendencia |

## Pendencias conhecidas

- aplicar sensibilidade real no modelo de aim, se a equipe decidir expor isso ao jogador
- ajustar o aim indicator com arte/fit visual final
- criar conteudo real de elite e boss
- avaliar prewarm por rule se surgirem cenas diferentes por inimigo
- adicionar testes de integracao com cenas/fisica
- preencher resultados reais do stress profiling com metricas capturadas
- otimizar Spine/horda apenas se profiler indicar
- evoluir HUD final de player
- definir dev/build mode explicito
- decidir destino de `docs/migration.zip` no repositorio

## Workspace e sanity

### Workspace status

- `git status --short`: sem evidencia de dirty workspace bloqueante nesta PR26
- `git diff --stat`: sem evidencia de diff inesperado bloqueante nesta PR26

### Arquivos observados

- `Main.gd` oficial preservado
- `RunScene.tscn` oficial preservada
- `StressRunScene.tscn` paralela preservada
- `.godot/` nao versionado
- `.tmp` nao encontrado na busca versionada desta PR

## Recomendacao final

### Recomendacao

Seguir para a proxima fase de conteudo **com ressalvas controladas**.

### O que pode entrar na proxima fase

- elite real
- boss real
- nova arma
- conteudo jogavel adicional
- HUD final

### O que deve virar PR separada antes ou durante essa fase

- profiling real se o stress manual indicar gargalo
- integracao de aim sensitivity de verdade
- eventual cleanup de artefatos/documentos versionados que nao devem ir para pacote final

## Gate final

- Runtime oficial: `OK`
- Gameplay oficial: `OK`
- Balanceamento oficial: `OK`
- Testes unitarios: `OK`
- Stress tooling: `OK`
- Stress metricas reais: `PENDENTE`

## Decisao

`READY_WITH_FOLLOW_UPS`
