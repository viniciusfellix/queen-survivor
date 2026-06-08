# AUDIT 05 - Reuse Or Rewrite Matrix

## Leitura rápida

- `Reaproveitar`: manter a intenção e parte importante da implementação
- `Reescrever`: manter só o comportamento desejado, não o desenho atual

## Matriz

| Sistema | Situação atual | Reaproveitar? | Reescrever? | Decisão | Justificativa |
|---|---|---|---|---|---|
| Estrutura `definitions/` + `data/` | Boa | Sim | Não | Reaproveitar | É o eixo mais profissional da base |
| `Main` | Boa | Sim | Não | Reaproveitar com ajustes | Root mínima faz sentido |
| `TestGaiaScene` | Funcional, mas provisória | Parcial | Parcial | Reorganizar | Composition root está correto; nome e mistura de responsabilidades não |
| `GameEvents` | Útil, mas largo | Sim | Parcial | Reaproveitar com poda | O conceito é bom |
| `InputManager` | Funciona, pouco idiomático | Não | Sim | Reescrever | Godot nativa resolve melhor para 1 player |
| `PoolManager` | Bom | Sim | Não | Reaproveitar | Survivors ganham muito com isso |
| `SaveManager` | Bom | Sim | Parcial | Reaproveitar com backend novo | Ponto único de save vale manter |
| `DeveloperAuditLogger` | Útil | Sim | Parcial | Reaproveitar com gating | Ferramenta de dev, não de runtime final |
| `DamagePayload` | Bom | Sim | Não | Reaproveitar | Contrato claro |
| `DamageResolver` | Bom | Sim | Não | Reaproveitar | Regra matemática central está correta |
| `HurtboxComponent` | Bom, pesado | Sim | Parcial | Reaproveitar com simplificação | O contrato vale, a implementação pode ser mais direta |
| `DirectionalAttackHitbox` | Bom, redundante | Sim | Parcial | Reaproveitar como base de ataque ativo | Deve convergir com outras hitboxes |
| `EnemyAttackHitbox` | Bom, redundante | Sim | Parcial | Reaproveitar | Mesmo argumento |
| `PlayerDashImpactArea` | Bom, redundante | Sim | Parcial | Reaproveitar | Dash ofensivo é válido; pipeline deve convergir |
| `PlayerController` | Funcional, grande | Sim | Não | Reaproveitar e fatiar | Reescrever do zero seria risco desnecessário |
| `PlayerRuntimeState` | Útil, mas largo | Sim | Parcial | Reaproveitar com enxugamento | Parte do estado pode voltar ao controller |
| `GaiaInitialWeaponController` | Funcional, grande | Sim | Parcial | Reaproveitar com refactor estrutural | Muita regra útil já existe |
| `EnemyBase` | Funcional, grande | Sim | Parcial | Reaproveitar com decomposição | Muita lógica valiosa já está codificada |
| `EnemySpawner` | Bom | Sim | Parcial | Reaproveitar com wiring mais explícito | Timeline + pooling é uma boa base |
| `CoinDrop` | Funciona, pouco idiomático | Parcial | Sim | Reescrever fluxo de coleta/magnetismo | Melhor usar `Area2D` dedicadas |
| `DropController` | Bom | Sim | Parcial | Reaproveitar | Responsabilidade está certa |
| `LevelUpOptionService` | Bom | Sim | Não | Reaproveitar | Serviço puro bem definido |
| Aplicação de upgrades | Espalhada | Não | Sim | Reescrever arquitetura | Principal gargalo de expansão |
| `RunController` | Funcional, grande | Sim | Parcial | Reaproveitar com fatiamento | Core da run já está codificado |
| `RunState` | Bom | Sim | Parcial | Reaproveitar com limpeza | Estrutura válida |
| `RewardResolver` | Bom | Sim | Não | Reaproveitar | Simples e correto |
| `RunHud` | Funcional, polling | Sim | Parcial | Reaproveitar com atualização por sinal | A UI em si vale; o padrão de atualização não |
| `LevelUpPanel` | Boa | Sim | Parcial | Reaproveitar | Só precisa ficar menos hardcoded |
| `ResultPanel` | Boa | Sim | Não | Reaproveitar | Faz exatamente o que deveria |
| `RunFeedbackLayer` | Opcional | Parcial | Parcial | Reavaliar depois | Não é prioridade decidir agora |
| `WorldFeedbackLayer` + `FloatingCombatText` | Boas | Sim | Parcial | Reaproveitar | O wiring pode ser simplificado |
| `SpineVisualControllerBase` | Bom | Sim | Não | Reaproveitar | Abstração com valor real |
| `SpineAnimationAdapterBase` | Bom | Sim | Parcial | Reaproveitar com simplificação | Menos reflexão, mesma ideia |
| `GaiaVisualController` | Bom | Sim | Não | Reaproveitar | Está alinhado ao contrato correto |
| `GoblinWarriorVisualController` | Bom | Sim | Não | Reaproveitar | Mesmo motivo |
| `GaiaSpineAdapter` / `GoblinWarriorSpineAdapter` | Muito finos | Parcial | Parcial | Absorver ou simplificar | Subclasses talvez não se justifiquem |
| `DebugOverlay` | Útil | Sim | Parcial | Reaproveitar em debug path | Não no runtime final |
| `PrototypeToolsPanel` | Útil | Sim | Parcial | Reaproveitar em debug path | Excelente ferramenta de smoke test |
| `RuntimeTreeSnapshot` | Útil | Sim | Não | Reaproveitar | Ferramenta clara de diagnóstico |
| `DebugEnemyLinkDrawer` | Baixo valor estrutural | Parcial | Parcial | Adiar decisão | Útil, mas não essencial |
| `.tmp` scenes | Residuais | Não | Não | Descartar | Sem valor de produto |

## Reaproveitamento recomendado por bloco

## Reaproveitar quase integralmente

- `definitions/*`
- `data/*` como conceito de content
- `PoolManager`
- `DamagePayload`
- `DamageResolver`
- `RewardResolver`
- `LevelUpOptionService`
- `ResultPanel`
- base visual/Spine

## Reaproveitar mantendo intenção, mas simplificando forte

- `GameEvents`
- `SaveManager`
- `PlayerController`
- `EnemyBase`
- `GaiaInitialWeaponController`
- `RunController`
- `RunHud`
- `HurtboxComponent`
- hitboxes atuais
- `DropController`
- debug stack

## Reescrever com abordagem Godot nativa

- `InputManager`
- fluxo de coleta/magnetismo de moedas
- arquitetura de aplicação de upgrades

## Descartar

- arquivos `.tmp`
- resources duplicados/residuais onde houver source of truth concorrente

## Decisão estratégica

O projeto **não pede reescrita total**.

Ele pede:

1. preservar o modelo data-driven;
2. preservar o contrato de combate;
3. preservar a separação gameplay/visual;
4. reescrever só os trechos em que a Godot nativa dá um caminho mais simples e previsível.
