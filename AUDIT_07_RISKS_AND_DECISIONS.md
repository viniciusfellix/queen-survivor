# AUDIT 07 - Risks And Decisions

## Objetivo

Registrar os principais riscos técnicos e as decisões arquiteturais que precisam ser tomadas com consciência na próxima etapa.

## 1. Riscos principais

## R1. Regressão ao simplificar sistemas que já funcionam

### Onde

- `gameplay/player/PlayerController.gd`
- `gameplay/enemies/EnemyBase.gd`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `gameplay/run/RunController.gd`

### Risco

Os scripts são grandes, mas carregam muita regra real já validada. Reescrever sem baseline pode perder:

- timings;
- regras de knockback;
- integração de dash;
- ordem dos eventos;
- reward/save.

### Decisão

Não reescrever tudo. Fatiar progressivamente.

## R2. Source of truth duplicada para arma/attack area

### Onde

- `gameplay/player/PlayerGaia.tscn`
- `data/weapons/weapon_gaia_initial.tres`
- `resources/combat/attack_areas/attack_area_gaia_initial_d.tres`
- `data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

### Risco

- editor mostra uma coisa;
- runtime usa outra;
- designers ajustam resource errada;
- bugs parecem aleatórios.

### Decisão

Escolher uma fonte única para a arma e documentá-la.

## R3. Event bus virar camada universal

### Onde

- `autoloads/GameEvents.gd`
- UI e save em geral

### Risco

Qualquer coisa passar a depender de `GameEvents`, tornando o projeto difícil de rastrear.

### Decisão

`GameEvents` deve ficar restrito a:

- eventos de run;
- eventos de UI global;
- persistência;
- telemetria global útil.

Integrações locais devem preferir sinais locais ou referências diretas.

## R4. Grupos demais como wiring implícito

### Onde

- `RunQuery`
- `RunHud`
- `EnemySpawner`
- `FollowCamera`
- `DropController`
- `WorldFeedbackLayer`

### Risco

- mudança de cena quebra wiring implicitamente;
- expansão para múltiplos players/summons/bosses fica confusa;
- ferramentas passam a depender da mesma cola estrutural.

### Decisão

Manter grupos para debug e descoberta leve, mas não para o wiring principal do jogo final.

## R5. Debug tooling contaminando runtime final

### Onde

- `ui/debug/DebugOverlay.tscn`
- `ui/debug/tools/PrototypeToolsPanel.tscn`
- `autoloads/DeveloperAuditLogger.gd`

### Risco

- custo extra;
- dependência de APIs de debug;
- confusão entre UI técnica e UI de jogo.

### Decisão

Mover mentalmente tudo isso para um modo debug, sem perder a ferramenta.

## R6. Reescrever moedas de forma simplista e perder “feel”

### Onde

- `gameplay/drops/CoinDrop.gd`

### Risco

Uma reescrita “muito limpa” pode deixar coleta menos responsiva.

### Decisão

Refazer usando `Area2D` nativas, mas validar sensação de coleta contra baseline.

## R7. Save migration prematura

### Onde

- `autoloads/SaveManager.gd`
- `runtime/SaveData.gd`

### Risco

Trocar backend de save muito cedo, ao mesmo tempo que várias regras mudam, dificulta isolar bugs.

### Decisão

Fazer save depois de baseline/limpeza e antes do refactor profundo do core, ou então encapsular sem trocar formato imediatamente.

## 2. Decisões arquiteturais recomendadas

## D1. Preservar o contrato de combate

### Decisão

Preservar formalmente:

- `BodyCollision`
- `Hitbox`
- `Hurtbox`
- `DamagePayload`
- `DamageResolver`

### Motivo

Esse é o ponto mais sólido e profissional do projeto.

## D2. Preservar data-driven por `Resource`

### Decisão

Não colapsar armas/inimigos/upgrades/maps em constantes hardcoded ou grandes scripts monolíticos.

### Motivo

O modelo de conteúdo do projeto é um dos ativos mais valiosos da base.

## D3. Reduzir abstração onde a Godot já resolve

### Decisão

Rever principalmente:

- input global;
- magnetismo/coleção de moedas;
- update do HUD;
- persistência manual de `Resource`.

### Motivo

Nesses pontos a abstração própria não trouxe ganho equivalente ao custo.

## D4. Não confundir “genérico” com “pronto para tudo”

### Decisão

Ao fatiar `EnemyBase`, `PlayerController` e `RunController`, preferir componentes locais e específicos antes de criar bases ultra genéricas.

### Motivo

O projeto já mostra sinais de genericidade precoce.

## D5. Consolidar uma cena principal oficial de gameplay

### Decisão

Promover a cena jogável atual para uma estrutura oficial de gameplay, deixando “test scene” de ser o nome/conceito central.

### Motivo

Isso melhora clareza arquitetural, onboarding e manutenção.

## D6. Separar UI de jogo e UI técnica

### Decisão

Criar um `DebugRoot` ou modo debug explícito.

### Motivo

Hoje a mistura é aceitável para protótipo, mas não para base durável.

## D7. Centralizar aplicação de upgrades

### Decisão

Criar um fluxo único de aplicação, com handlers específicos por domínio.

### Motivo

Esse é o maior risco de explosão de complexidade ao adicionar conteúdo.

## 3. Decisões que precisam de inspeção manual

## PIM1. Qual attack area da Gaia é a correta

Precisa inspeção manual de jogo/editor:

- `resources/combat/attack_areas/attack_area_gaia_initial_d.tres`
- `data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

É preciso confirmar:

- qual shape está em uso real;
- qual shape representa melhor o ataque desejado;
- qual resource deve permanecer como oficial.

## PIM2. `RunFeedbackLayer` vale ficar?

Pergunta:

- ele adiciona clareza ou só duplica sinais já cobertos por HUD e world feedback?

Precisa avaliação com playtest e preferência de UX.

## PIM3. `PlayerRuntimeState` e `RunState` continuam `Resource`?

Pergunta:

- o benefício editorial/organizacional compensa?
- ou `RefCounted`/classes runtime simples bastam?

Não é urgente. Exige decisão de coerência arquitetural.

## PIM4. Adapters Spine finos devem continuar?

Pergunta:

- `GaiaSpineAdapter.gd` e `GoblinWarriorSpineAdapter.gd` devem existir como pontos explícitos por personagem?

Se a equipe valoriza extensibilidade explícita por personagem, podem continuar.
Se quer simplificação, podem ser absorvidos pela base.

## 4. Decisões proibidas nesta fase

Até a próxima etapa, não tomar estas decisões impulsivamente:

- reescrever o combate do zero;
- remover `DamagePayload`/`DamageResolver`;
- trocar `CharacterBody2D` por solução manual;
- colapsar `Resource` em config hardcoded;
- remover `PoolManager`;
- remover toda a camada de debug sem antes separar o que é útil.

## 5. Conclusão decisional

### O que deve ser protegido

- contrato de combate
- data-driven
- separação gameplay/visual
- pooling
- services puros

### O que deve ser simplificado

- input
- HUD
- moedas
- aplicação de upgrades
- wiring por grupo/reflexão
- monólitos centrais

### O que deve ser removido

- `.tmp`
- duplicidades de resource/source of truth

### Estratégia recomendada

Evolução controlada, não reboot total.

O projeto já tem um esqueleto forte. O trabalho agora é **tirar complexidade acidental sem destruir a complexidade intencional que já funciona**.
