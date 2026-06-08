# AUDIT 06 - Step By Step Migration Roadmap

## Fase 0 - Preservação e baseline

### Objetivo

Congelar o comportamento atual e garantir uma linha de base de regressão antes de qualquer mudança estrutural.

### Arquivos prováveis

- `gameplay/test/TestGaiaScene.tscn`
- `gameplay/player/PlayerGaia.tscn`
- `gameplay/enemies/EnemyBase.tscn`
- `gameplay/run/RunController.gd`
- `gameplay/player/PlayerController.gd`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `autoloads/*`
- `ui/*`

### O que não mexer

- balanceamento
- layers/masks
- timings de ataque
- duração/cooldown de dash
- economia de run

### Testes esperados

- boot do projeto
- cena principal carrega
- Gaia movimenta
- dash funciona
- arma ataca
- inimigo persegue e causa dano
- moeda dropa e coleta
- level up abre
- resultado abre
- save persiste

### Critério de conclusão

- checklist manual fechado
- baseline registrada em documento/test plan

### Risco

- médio: sem baseline, qualquer simplificação vira regressão silenciosa

## Fase 1 - Auditoria e limpeza sem mudar gameplay

### Objetivo

Remover ruído, consolidar source of truth e limpar resíduos sem alterar comportamento jogável.

### Arquivos prováveis

- `gameplay/test/*.tmp`
- `gameplay/player/*.tmp`
- `resources/combat/attack_areas/*`
- `data/weapons/attack_areas/*`
- `docs/*`
- `project.godot`

### O que não mexer

- fluxo de dano
- física do player
- lógica de inimigo
- save e UI de gameplay

### Testes esperados

- abrir projeto no editor sem referências quebradas
- validar que `WeaponDefinition` e cena do player apontam para a mesma fonte de config
- validar que não há resources órfãos essenciais

### Critério de conclusão

- arquivos temporários removidos
- nomenclatura crítica regularizada
- source of truth por sistema documentada

### Risco

- baixo a médio: referência perdida em resource/cena

## Fase 2 - Refatoração de arquitetura Godot nativa

### Objetivo

Substituir soluções pouco idiomáticas por fluxos nativos da Godot sem alterar a experiência de jogo.

### Arquivos prováveis

- `autoloads/InputManager.gd`
- `gameplay/player/PlayerController.gd`
- `gameplay/drops/CoinDrop.gd`
- `gameplay/drops/CoinDrop.tscn`
- `ui/hud/RunHud.gd`
- `autoloads/SaveManager.gd`
- `runtime/SaveData.gd`

### O que não mexer

- regras matemáticas de dano
- conteúdo de upgrades
- visual Spine
- pooling

### Testes esperados

- input igual ao baseline
- moedas continuam coletando e magnetizando
- HUD atualiza corretamente sem polling excessivo
- save carrega e grava corretamente

### Critério de conclusão

- input direto no player
- coleta/magnetismo mais nativos
- HUD por sinais
- persistência simplificada ou ao menos encapsulada

### Risco

- médio: mudanças localizadas, mas sensíveis ao feel

## Fase 3 - Reconstrução mínima do core

### Objetivo

Reduzir monólitos centrais sem reescrever o jogo todo.

### Arquivos prováveis

- `gameplay/player/PlayerController.gd`
- `gameplay/player/PlayerDashImpactArea.gd`
- `gameplay/enemies/EnemyBase.gd`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `gameplay/run/RunController.gd`
- novos componentes locais derivados desse fatiamento

### O que não mexer

- `DamageResolver`
- `RewardResolver`
- `LevelUpOptionService`
- resources data-driven

### Testes esperados

- mesmos timings do baseline
- mesmos danos
- mesmas regras de dash
- mesmas regras de morte/drop/reward

### Critério de conclusão

- `PlayerController`, `EnemyBase`, `GaiaInitialWeaponController` e `RunController` menores
- responsabilidades separadas com clareza
- nenhuma regressão funcional visível

### Risco

- alto: é a fase de maior risco técnico, porque mexe nos monólitos

## Fase 4 - Reintrodução de sistemas reaproveitados

### Objetivo

Reencaixar de forma limpa os sistemas que valem a pena preservar depois da limpeza do core.

### Arquivos prováveis

- `autoloads/GameEvents.gd`
- `autoloads/DeveloperAuditLogger.gd`
- `visual/spine/*`
- `ui/debug/*`
- `ui/world_feedback/*`
- `gameplay/spawners/EnemySpawner.gd`

### O que não mexer

- baseline já estabilizada do core
- fórmulas de run e dano

### Testes esperados

- debug continua útil
- feedback visual continua funcionando
- logs continuam disponíveis em debug
- spawner continua respeitando timeline

### Critério de conclusão

- sistemas reaproveitados ficam acoplados de forma mais limpa
- tooling e runtime de jogo ficam mais separados

### Risco

- médio: risco de “reatar” dependências antigas sem perceber

## Fase 5 - Testes regressivos

### Objetivo

Comparar comportamento antes e depois da migração para garantir que a simplificação não quebrou o jogo.

### Arquivos prováveis

- cenas de runtime
- scripts centrais
- documentos de teste

### O que não mexer

- arquitetura principal
- conteúdo/balance

### Testes esperados

- movimento e dash
- dano recebido e causado
- knockback
- spawn por timeline
- drops e magnetismo
- level-up
- reward final
- save
- reload de cena após resultado
- overlays de debug

### Critério de conclusão

- checklist de regressão fechada
- principais cenários validados manualmente

### Risco

- médio: survivor-like costuma mascarar bugs sistêmicos em cenários com pouca densidade

## Fase 6 - Documentação

### Objetivo

Atualizar a documentação para refletir a arquitetura consolidada.

### Arquivos prováveis

- `docs/01_architecture/*`
- `docs/02_lifecycles/*`
- `docs/03_domains/*`
- `docs/06_reference/*`
- novos ADRs se necessário

### O que não mexer

- lógica de gameplay

### Testes esperados

- documentação bate com a árvore real
- source of truth dos resources está clara
- layers/masks atualizadas
- fluxo de upgrade/save/run documentado

### Critério de conclusão

- onboarding possível só pela docs
- próximos refactors ficam mais baratos

### Risco

- baixo: risco maior é documentação ficar defasada de novo

## Ordem recomendada dentro do roadmap

1. baseline
2. limpeza de resíduos e source of truth
3. input/HUD/moedas/save
4. fatiamento de player/inimigo/arma/run
5. reintegração de debug/spine/tooling
6. regressão ampla
7. documentação final

## Coisas que não devem ser mexidas cedo demais

- `DamageResolver`
- contrato `DamagePayload`
- layers/masks atuais
- separação gameplay/visual
- resources de conteúdo já funcionais
- pooling

## Marco de sucesso da migração

Ao final, a base deve apresentar:

- cena principal clara de gameplay
- menos scripts monolíticos
- menos dependência de grupos para wiring principal
- menos `has_method`/`call` no runtime crítico
- HUD e UI mais reativas por sinais
- moedas mais idiomáticas
- upgrades aplicados por arquitetura centralizada
- debug separado de runtime final
