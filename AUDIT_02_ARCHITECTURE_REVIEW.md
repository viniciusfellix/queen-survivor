# AUDIT 02 - Architecture Review

## Objetivo

Este documento faz a revisão técnica do projeto sob a ótica de Godot 4.x idiomática, survivor-like/roguelike e sustentabilidade de médio prazo.

Escopo:

- estrutura geral do projeto;
- arquitetura Godot;
- combate;
- player;
- inimigos;
- drops/moedas;
- XP/level-up/upgrades;
- run/resultado/save;
- UI/feedback;
- Spine/visual;
- debug/ferramentas;
- performance/manutenção.

## Veredito geral

O projeto **não está “errado” estruturalmente**. Ele já tem várias decisões corretas e maduras:

- separação entre gameplay e visual;
- uso consistente de `Resource` para definições editáveis;
- separação de `BodyCollision`, `Hitbox` e `Hurtbox`;
- uso de `CanvasLayer` para UI de run;
- centralização de regras matemáticas em serviços puros (`DamageResolver`, `RewardResolver`, `LevelUpOptionService`);
- uso consciente de pooling;
- esforço claro de documentação e telemetria.

O problema principal não é “quebrado”; é **complexidade excessiva e dispersão de responsabilidades**. O projeto frequentemente implementa uma camada própria onde a Godot já oferece um caminho mais simples e previsível.

Em resumo:

- **funcional**: sim;
- **modular**: parcialmente;
- **idiomático para Godot**: parcialmente;
- **superengenheirado em pontos sensíveis**: sim;
- **recuperável sem reboot total**: sim.

## 1. Estrutura geral do projeto

## O que está bom

Separação de pastas:

- `autoloads/` para serviços globais;
- `definitions/` para classes-base de `Resource`;
- `data/` para instâncias `.tres`;
- `gameplay/` para runtime jogável;
- `runtime/` para estado temporário;
- `ui/` para interface;
- `visual/` para apresentação;
- `docs/` para documentação viva.

Essa topologia é melhor do que a média de protótipo Godot.

## O que está fraco

### 1. Cena principal ainda é técnica

Fluxo atual:

- `project.godot`
- `scenes/Main.tscn`
- `scenes/Main.gd`
- `gameplay/test/TestGaiaScene.tscn`

`TestGaiaScene.tscn` é, na prática, a cena principal do jogo, mas vive em `gameplay/test/`. Isso faz a base parecer transitória mesmo quando já concentra o core inteiro.

### 2. Arquivos residuais e nomenclatura suspeita

Achados:

- `gameplay/test/TestGaiaScene.tscn6158799705.tmp`
- `gameplay/test/TestGaiaScene.tscn6275747883.tmp`
- `gameplay/test/TestGaiaScene.tscn6283063278.tmp`
- `gameplay/player/PlayerGaia.tscn16296637380.tmp`
- `gameplay/player/PlayerGaia.tscn2451716848.tmp`
- `data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

Isso não é só estética; afeta confiança no projeto como source of truth.

### 3. Dois eixos de organização para resources

Há uma convenção dominante:

- tipo em `definitions/`
- instância em `data/`

Mas existe também:

- `resources/combat/attack_areas/attack_area_gaia_initial_d.tres`

Isso fragmenta o mapa mental do projeto.

## Avaliação

| Área | Avaliação | Observação |
|---|---|---|
| Pastas | Boa | Organização geral acima da média |
| Nomes | Irregular | `.tmp`, `.tres.tres`, duplicidade de attack area |
| Separação gameplay/UI/visual | Boa | Conceito correto |
| Separação debug/core | Boa | Ferramental bem isolado por pasta |
| Cenas de composição | Razoável | Cena técnica concentra tudo |

## 2. Arquitetura Godot

## Nodes e tipos

### Uso correto

- `CharacterBody2D` para player e inimigo: correto
- `Area2D` para hitbox/hurtbox/impact area: correto
- `CanvasLayer` para HUD, level-up, result, debug: correto
- `Resource` para definições de arma, queen, inimigo, mapa, upgrade: correto
- `CollisionShape2D` runtime montada a partir de resources: válido

### Uso questionável

- uso amplo de `RefCounted` como contrato de domínio onde `Resource` ou script local poderia bastar;
- excesso de reflexão com `has_method` + `call` em vários pontos de runtime;
- forte dependência de grupos como mecanismo estrutural, e não apenas utilitário.

## Grupos

Grupos atuais:

- `player`
- `enemy`
- `hurtbox`
- `enemy_attack_hitbox`
- `player_weapon`
- `run_controller`

### Onde ajudam

- localizar o único `RunController`;
- localizar player em cena técnica;
- debug tools e overlays.

### Onde atrapalham

- `RunHud`, `EnemySpawner`, `DropController`, `FollowCamera`, `WorldFeedbackLayer`, `RunQuery` e outros fazem resolução por grupo em runtime;
- isso cria acoplamento implícito entre scripts e árvore;
- reduz previsibilidade em cenas futuras, elites, bosses, summons e multiplayer/local coop eventual.

### Julgamento

Grupos aqui são **úteis**, mas **usados demais como cola arquitetural**.

## Signals

`GameEvents.gd` é o barramento global.

### Acertos

- UI desacoplada do gameplay;
- save escuta fim de run;
- feedback escuta dano/moeda/level-up/resultado;
- weapon cooldown exposto para HUD.

### Problemas

- `GameEvents` ficou largo demais para um protótipo desse tamanho;
- vários fluxos poderiam ser sinais locais entre cena raiz e filhos, não globais;
- existe risco de “event bus por padrão” virar dependência universal.

### Julgamento

`GameEvents` é **válido e reaproveitável**, mas precisa virar barramento de eventos realmente globais, não de qualquer integração entre dois nós.

## Autoloads

Autoloads atuais:

- `App`
- `GameEvents`
- `InputManager`
- `PoolManager`
- `SaveManager`
- `DeveloperAuditLogger`

### Avaliação

| Autoload | Julgamento | Motivo |
|---|---|---|
| `App` | Válido, mas pequeno demais | Poderia ler `ProjectSettings`; hoje quase não precisa ser autoload |
| `GameEvents` | Útil | Mas precisa emagrecer |
| `InputManager` | Exagerado | Para um único player local, Godot resolve de modo mais simples |
| `PoolManager` | Útil | Especialmente para survivors |
| `SaveManager` | Útil | Bom ponto único de persistência |
| `DeveloperAuditLogger` | Útil em debug | Não deveria contaminar release |

## Scenes, composição e herança

O projeto usa mais composição do que herança de cena, o que é bom.

Não há abuso de cenas herdadas. A parte problemática não é herança; é que a cena técnica virou composition root do jogo inteiro.

## Resources data-driven

Esse é um dos melhores lados do projeto.

### Acertos reais

- `WeaponDefinition`
- `EnemyDefinition`
- `QueenDefinition`
- `MapDefinition`
- `UpgradeDefinition`
- `UpgradePoolDefinition`
- `EnemyAttackDefinition`
- `AttackAreaDefinition`
- `HurtboxAreaDefinition`

Esses recursos são coerentes com survivor-like data-driven.

### Excesso

Algumas definições estão corretas, mas o runtime ainda duplica ou mistura config da cena com config do resource.

Exemplo:

- `gameplay/player/PlayerGaia.tscn`
- `data/weapons/weapon_gaia_initial.tres`
- `resources/combat/attack_areas/attack_area_gaia_initial_d.tres`
- `data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

O conceito data-driven está certo; o source of truth ainda não está suficientemente claro.

## 3. Combate, dano, hitbox e hurtbox

## O que está correto

O projeto já adotou um contrato profissional:

- `BodyCollision` para física;
- `Area2D` ofensiva para dano;
- `Area2D` vulnerável para recepção;
- `DamagePayload` como contrato;
- `DamageResolver` como regra matemática;
- layers/masks explícitas.

Isso é bom e deve ser preservado.

## O que está superengenheirado

### 1. Shapes runtime recriadas via `Resource` em toda instância

`HurtboxComponent`, `EnemyAttackHitbox`, `DirectionalAttackHitbox` e `PlayerDashImpactArea` constroem `CollisionShape2D` dinamicamente a partir de resources.

Isso é defensável se:

- shapes mudam dinamicamente por upgrade;
- o mesmo attack profile serve para várias entidades;
- o design precisa editar tudo por `Resource`.

Mas aqui a solução foi aplicada em praticamente tudo, inclusive casos simples de shape estável.

### 2. Dano depende demais de nós intermediários

Fluxo atual típico:

- hitbox detecta `HurtboxComponent`
- hurtbox resolve receiver
- hitbox monta `DamagePayload`
- receiver calcula ou delega dano

Isso funciona, mas está carregado de camadas para um protótipo com:

- um player;
- um inimigo comum;
- uma arma melee;
- um dash ofensivo.

### 3. Repetição entre ataque de arma, ataque inimigo e dash ofensivo

Há três pipelines similares:

- `DirectionalAttackHitbox.gd`
- `EnemyAttackHitbox.gd`
- `PlayerDashImpactArea.gd`

Todos fazem:

- montar shapes runtime;
- detectar hurtbox;
- evitar hit repetido;
- aplicar payload;
- às vezes knockback.

Isso indica abstração insuficiente no nível certo e abstração excessiva no lugar errado.

## O que manter como contrato

Manter:

1. separação `BodyCollision` != dano;
2. `Area2D` para ataque;
3. `Area2D` para hurtbox;
4. `DamagePayload`;
5. `DamageResolver`;
6. layers/masks oficiais.

Esse contrato está bom.

## Arquitetura profissional sugerida

### Contratos

- `HurtboxComponent` continua sendo um `Area2D` com `CollisionShape2D`;
- receiver continua sendo o dono do HP (`PlayerController`, `EnemyBase`, futuros bosses);
- `DamagePayload` continua existindo;
- `DamageResolver` continua central.

### Simplificação

#### Ataque ativo de arma

Usar:

- `Area2D`
- filhos `CollisionShape2D` ou shape pronta em cena
- script `AttackHitbox2D.gd`

Fluxo:

1. arma instancia hitbox;
2. hitbox recebe um `AttackSpec`/dados de ataque;
3. `area_entered` e, opcionalmente, `get_overlapping_areas()` na ativação;
4. resolve `HurtboxComponent`;
5. entrega `DamagePayload`;
6. opcional: aplica knockback por contrato.

#### Dano por contato inimigo

Usar:

- `EnemyAttackHitbox` como `Area2D` persistente no inimigo;
- `Timer` local ou cooldown por alvo;
- shapes definidas pela cena do inimigo ou resource do inimigo.

Não precisa de uma pilha tão reflexiva quanto a atual.

#### Dano por projétil

Estrutura ideal:

- `Projectile.tscn`
- `Projectile.gd`
- `Area2D`
- `CollisionShape2D`
- `DamagePayload` embutido ou `ProjectileDefinition`

#### Dano por dash

Separar conceitualmente:

- dash movement no player;
- dash offensive area opcional, ligada só durante dash;
- mesma infraestrutura de hitbox, mas com `source_kind = dash`.

Hoje o dash ofensivo está tecnicamente correto, mas duplicado.

## Layers e masks

Configuração atual:

- 1 `World`
- 2 `PlayerBody`
- 3 `EnemyBody`
- 4 `PlayerAttackHitbox`
- 5 `EnemyHurtbox`
- 6 `EnemyAttackHitbox`
- 7 `PlayerHurtbox`
- 8 `DropPickup`

Isso está bom.

### Julgamento

O sistema de combate está **conceitualmente certo**, mas **pesado demais para a fase do projeto**. Deve ser simplificado preservando:

- a divisão de responsabilidade;
- os payloads;
- as layers;
- a clareza data-driven.

## 4. Gaia / player

## O que está bom

`PlayerController.gd` concentra o core do player:

- movimento;
- mira;
- dash;
- dano;
- morte;
- feedback;
- upgrades;
- integração com arma.

`CharacterBody2D` é apropriado para Gaia.

`PlayerRuntimeState.gd` ajuda a formalizar estado transitório e separar runtime de save.

Separação visual/gameplay também está certa:

- `PlayerController` decide;
- `GaiaVisualController` representa.

## O que está ruim

### 1. `PlayerController.gd` está grande demais

- arquivo: `gameplay/player/PlayerController.gd`
- tamanho: 767 linhas

Ele já está no limite onde pequenas mudanças começam a gerar regressão lateral.

### 2. `PlayerRuntimeState` está misturando dado útil com espelho transitório demais

Ele guarda:

- HP e defesa: bom
- move speed: bom
- state de dash: bom
- aim/facing/move direction: aceitável
- current gameplay state / visual state: discutível

Parte disso deveria continuar no controller e não no resource.

### 3. `InputManager` é mais complexo que o necessário

Para um jogo single-player local, o caminho idiomático seria:

- `PlayerController` lê `Input.get_vector(...)`
- `dash` via `Input.is_action_just_pressed("dash")`
- mira por mouse ou analógico direto no controller

`InputManager` pode existir se a intenção for:

- replay/input recording;
- AI usando o mesmo contrato;
- futuro multiplayer local.

Hoje ele parece mais um serviço global do que uma necessidade real.

### 4. Dash está acoplado a muita regra lateral

O dash conversa com:

- runtime state;
- hurtbox;
- body collision;
- impact area;
- visual animation scale;
- weapon cooldown policy.

Isso é funcional, mas pesado.

## Proposta de arquitetura

### Manter em `PlayerController`

- movimento;
- leitura de input;
- estados de vida;
- entrada e saída de dash;
- receber dano.

### Extrair em componente local

- `DashController` ou `PlayerDashComponent`
  - cooldown
  - duração
  - distância
  - toggles de colisão
  - integração com impact area

Não como autoload. Como filho do player ou script local dedicado.

### Manter em `Resource`

- `QueenDefinition`
- `QueenDashDefinition`
- hurtbox config
- stats base

### Evitar colocar em `Resource`

- posição atual;
- animação atual;
- cooldown atual;
- timers transitórios.

## 5. Inimigos

## O que está bom

`EnemyBase.gd` já tenta ser uma base runtime para inimigos:

- HP;
- perseguição;
- dano recebido;
- morte;
- rewards;
- visual desacoplado.

Isso é uma boa intenção.

## O que está ruim

### 1. `EnemyBase.gd` está grande e carrega várias responsabilidades

- arquivo: `gameplay/enemies/EnemyBase.gd`
- tamanho: 813 linhas

Hoje ele mistura:

- vida;
- perseguição;
- body bump;
- slide em torno do player;
- knockback recebido;
- ataque de contato;
- visual sync;
- morte;
- pooling hooks.

É demais para uma base única.

### 2. Movimento de inimigo comum já está preparado para muitos casos ao mesmo tempo

O script atual quer suportar:

- chase padrão;
- bump entre inimigos;
- slide no corpo do player;
- knockback de arma;
- knockback de dash;
- blend entre chase e knockback.

Isso funciona, mas está cedo demais para estar tudo concentrado num único script-base.

### 3. `EnemySpawner` depende bastante da estrutura atual da run

Ele resolve:

- timeline via `RunQuery`;
- player por grupo;
- enemy root por path/sibling;
- configura inimigo por `setup()`.

Está funcional, mas ainda muito costurado à cena técnica.

## Arquitetura recomendada

### Agora

Manter:

- `EnemyBase`
- `EnemyDefinition`
- `EnemySpawner`
- `EnemyAttackHitbox`

Mas dividir mentalmente em três camadas:

1. locomotion/chase;
2. combat receiver + attack;
3. reward/death.

### Futuro sustentável

- `EnemyActor` ou `EnemyBase`
- `EnemyMovementComponent`
- `EnemyCombatComponent`
- `EnemyRewardComponent`

Para elites/bosses:

- manter `EnemyDefinition` como base de stats;
- cena própria para cada família;
- scripts especializados para padrões de ataque;
- não forçar tudo a caber no mesmo `EnemyBase.gd`.

## 6. Moedas, drops e magnetismo

## O que está bom

- `DropController` escuta morte do inimigo;
- `CoinDrop` representa moeda física;
- coleta é física e visível;
- magnetismo existe;
- reward final não depende da moeda visual diretamente.

Isso é uma boa base para survivor-like.

## O que está excessivo

O magnetismo atual é implementado como lógica manual por script, o que funciona, mas pode ser simplificado com infraestrutura mais nativa.

## Solução idiomática Godot sugerida

### Estrutura de moeda

`CoinDrop.tscn`

- `Node2D` root ou `Area2D` root
- `Sprite2D`
- `Area2D` de coleta
- `CollisionShape2D` de coleta
- opcional: `Area2D` de magnetismo
- opcional: `CollisionShape2D` de magnetismo

### Fluxo

#### Raio de magnetismo

- `Area2D` maior
- mask contra player collector area ou contra grupo do player
- `body_entered`/`area_entered` ativa modo magnetizado

#### Raio de coleta

- `Area2D` menor
- ao detectar o player, coleta imediatamente

#### Movimento magnetizado

- o script da moeda pode continuar movendo em direção ao player enquanto magnetizada;
- isso é simples e idiomático;
- não precisa de estrutura extra além do estado `is_magnetized` e referência ao player.

### Separar três coisas

- moeda física coletável;
- XP direta não física;
- futuros drops especiais.

Hoje essa separação conceitual já existe parcialmente e deve continuar.

## 7. XP, level-up e upgrades

## O que está bom

- `UpgradeDefinition`
- `UpgradePoolDefinition`
- `LevelUpOptionService`

A separação entre:

- seleção de opções;
- apresentação de opções;
- aplicação do upgrade

é uma boa direção.

## O que está ruim

A **aplicação dos upgrades está espalhada**.

Hoje a lógica entra em:

- `RunController`
- `PlayerController`
- `GaiaInitialWeaponController`
- possivelmente outros consumidores futuros

Isso é o ponto mais delicado para expansão.

## Arquitetura recomendada

### Manter separado

1. `UpgradeDefinition`: o que o upgrade é
2. `LevelUpOptionService`: como escolher opções
3. `LevelUpPanel`: como mostrar opções

### Centralizar aplicação

Criar futuramente um ponto único de roteamento, por exemplo:

- `RunUpgradeApplier`

Responsabilidade:

- recebe `UpgradeDefinition`
- classifica tipo/target
- aplica no player, arma, economia, coleta etc.

Ele não precisa virar script gigante se for montado por handlers:

- player handler
- weapon handler
- drop/economy handler
- future artifact handler

### Para expansão futura

Arquitetura deve suportar:

- armas múltiplas;
- artefatos passivos;
- summons;
- rerolls;
- bans/blocks;
- upgrades de raridade.

O modelo de `Resource` atual ajuda nisso. O espalhamento da aplicação é o que precisa melhorar.

## 8. Run, resultado e save

## O que está bom

- `RunState` separado de `SaveData`;
- `RunController` coordena a run;
- `RewardResolver` calcula recompensa;
- `SaveManager` aplica resultado e persiste;
- `ResultPanel` só exibe.

Essa separação está boa.

## O que está ruim

### 1. `RunController.gd` está muito grande

- arquivo: `gameplay/run/RunController.gd`
- tamanho: 576 linhas

Ele já acumula:

- timer;
- XP;
- moedas;
- kills;
- level-up flow;
- upgrade apply flow;
- result build;
- pause policy;
- debug actions.

### 2. Save em JSON manual para um `Resource`

`SaveData.gd` já é `Resource`, mas `SaveManager.gd` serializa manualmente via JSON.

Isso é aceitável para protótipo, porém:

- duplica trabalho;
- exige manutenção de schema manual;
- adiciona parsing e defaults customizados desnecessários.

### 3. `RunResultPayload` como `RefCounted` é aceitável, mas simples

Sem problema grave aqui, só observar que é DTO puro.

## Estrutura realista de save para a fase atual

Sem overengineering:

- manter um único save slot;
- persistir:
  - `total_xp`
  - `total_money`
  - `completed_maps`
  - `last_run_summary`
  - `basic_records`
  - `settings`
- ignorar criptografia/obfuscação agora;
- preferir `ResourceSaver`/`ResourceLoader` quando a migração acontecer.

Risco real do JSON hoje:

- schema drift manual;
- erro silencioso em chave;
- maior chance de inconsistência entre código e persistência.

## 9. UI e feedback

## O que está bom

- UI está majoritariamente desacoplada do gameplay;
- `CanvasLayer` usado corretamente;
- `ResultPanel` não calcula recompensa;
- `LevelUpPanel` não aplica upgrade;
- feedback de mundo separado do feedback textual.

## O que está ruim

### 1. `RunHud` mistura HUD com consulta técnica

Ele consulta `get_debug_data()` do player e do run controller.

Isso é um anti-pattern: HUD de jogo não deveria depender de API de debug.

### 2. Debug UI e game UI convivem na mesma cena principal

`TestGaiaScene.tscn` contém:

- HUD de jogo
- feedback de jogo
- level-up
- result panel
- debug overlay
- prototype tools

Isso é prático para protótipo, mas deve ser reorganizado depois.

### 3. `RunFeedbackLayer` é funcional, porém redundante

Há:

- feedback textual geral
- floating combat text

Ele não está errado, mas pode acabar como duplicação de canal visual.

## Julgamento

UI do jogo está **mais correta do que a média**, mas a UI técnica está muito misturada no mesmo root.

## 10. Spine e visual

## O que está correto

Aqui o projeto está surpreendentemente sólido.

Boas decisões:

- gameplay não decide por animação;
- visual lê estado e representa;
- `SpineVisualControllerBase` e `SpineAnimationAdapterBase` têm intenção clara;
- Gaia e Goblin possuem controllers próprios;
- blink overlay e dash time scale são recursos visuais legítimos;
- tracks superiores para overlay fazem sentido.

## O que está excessivamente abstrato

### 1. Subclasses muito finas

- `GaiaSpineAdapter.gd`
- `GoblinWarriorSpineAdapter.gd`

Hoje quase só especializam nome/log/publish flag.

### 2. Resolução dinâmica excessiva

Há busca por `has_method`, `call`, `find first spine sprite`, `resolve adapter`.

Para tooling isso é tolerável; para runtime principal é mais indireção do que o necessário.

### 3. Controllers visuais ainda conversam demais com nomes de estado do gameplay

Funciona, mas vale no futuro tipar/normalizar melhor esses estados.

## Julgamento

O subsistema visual/Spine está **conceitualmente certo e reaproveitável**. Ele precisa mais de simplificação e redução de reflexão do que de reescrita.

## 11. Debug, logs e ferramentas técnicas

## Utilidade real

### `DeveloperAuditLogger`

Útil para:

- QA técnico;
- inspeção de lifecycle;
- auditoria manual;
- canais específicos.

### `RuntimeTreeSnapshot`

Útil para diagnóstico estrutural e documentação.

### `DebugOverlay`

Útil no desenvolvimento, não no runtime final.

### `PrototypeToolsPanel`

Útil para smoke testing e fluxo de protótipo.

### `DebugEnemyLinkDrawer`

Baixa utilidade fora de debugging momentâneo.

## Problema principal

As ferramentas são boas, mas estão muito presentes no runtime jogável central.

Elas devem:

- ficar fora de builds finais;
- idealmente ser carregadas por flag de debug;
- não moldar a arquitetura principal do jogo.

## 12. Performance e manutenção

## Pontos mais críticos

### Scripts grandes demais

| Arquivo | Linhas | Risco |
|---|---:|---|
| `gameplay/enemies/EnemyBase.gd` | 813 | responsabilidade demais |
| `gameplay/player/PlayerController.gd` | 767 | acoplamento lateral alto |
| `gameplay/weapons/gaia/GaiaInitialWeaponController.gd` | 647 | arma + upgrade + cooldown + spawn |
| `gameplay/run/RunController.gd` | 576 | coordenação excessiva |
| `ui/hud/RunHud.gd` | 397 | HUD muito acoplada |

### Resolução por grupo / busca

Há várias ocorrências de:

- `get_nodes_in_group(...)`
- `get_node_or_null(...)`
- `has_method(...)`
- `call(...)`

Em um survivor-like com hordas, isso vira dívida operacional rapidamente.

### Polling onde sinais bastariam

Exemplo principal:

- `RunHud.gd`

### Duplicação de runtime shape building

O custo não é absurdo hoje, mas a complexidade de manutenção é maior do que o ganho imediato.

## 13. Conclusão

### O projeto está incorreto?

Não.

### O projeto está superengenheirado em áreas importantes?

Sim.

### O projeto pode virar uma base profissional sem recomeçar do zero?

Sim.

### Núcleo que vale preservar

- modelo data-driven por `Resource`;
- separação gameplay/visual;
- contrato hitbox/hurtbox/payload;
- `DamageResolver`;
- `RewardResolver`;
- `SaveManager` como ponto de entrada;
- `PoolManager`;
- visual/Spine base;
- boa parte da UI.

### Núcleo que precisa simplificação séria

- `PlayerController`;
- `EnemyBase`;
- `GaiaInitialWeaponController`;
- `RunController`;
- `RunHud`;
- uso global de grupos/reflexão/event bus.

### Diagnóstico final

O projeto já possui uma espinha dorsal aproveitável, mas precisa sair de um estágio “protótipo com arquitetura própria para tudo” e entrar num estágio “Godot nativa primeiro, abstração só quando reduz custo real”.
