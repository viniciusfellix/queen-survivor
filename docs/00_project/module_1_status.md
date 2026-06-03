# Estado Atual — Módulo 1: Core, Gaia e Arena Infinita

## Status consolidado

O Módulo 1 está funcionalmente implementado e validado após auditoria, refatoração, comentários inline, regressão e migração do combate modular. O próximo desenvolvimento deve partir desta base, sem restaurar soluções antigas removidas.

## Implementado

### Gameplay

- Gaia jogável, movimento e mira direcional independente.
- Arena técnica infinita e câmera seguindo a Queen.
- Goblin perseguidor instanciado por timeline de spawn.
- Arma inicial direcional com dano físico + mágico.
- Hitbox ofensiva da Gaia configurada como retângulo por resource.
- Hurtboxes independentes para Gaia e Goblin.
- Ataque corporal do Goblin por `EnemyAttackHitbox`.
- Fraquezas e resistências resolvidas por componente de dano.
- XP direta/única e level-up com três opções.
- Upgrades de player, arma, magnetismo e área ofensiva.
- Moeda física com magnetismo e coleta.
- Vitória, derrota, resultado e save básico.
- Feedback flutuante/flash vermelho da Gaia e flash claro do Goblin.
- Ferramentas técnicas: audit logger, overlay, painel do protótipo e snapshot runtime.

### Arquitetura consolidada

- `RunState.is_ending` bloqueia gameplay durante encerramento.
- `RunQuery` centraliza consulta de bloqueio de gameplay.
- `RewardResolver` calcula dinheiro final.
- `DamageResolver` calcula defesa/fraqueza/resistência.
- `LevelUpOptionService` seleciona upgrades válidos.
- `SpineAnimationAdapterBase` e `SpineVisualControllerBase` removem duplicação visual.
- `CombatShapeDefinition`, `AttackAreaDefinition` e `HurtboxAreaDefinition` suportam shapes editáveis.
- `HurtboxComponent` é reutilizado por player e inimigos.
- `EnemyAttackDefinition` e `EnemyAttackHitbox` padronizam ataques de inimigos.

## Valores validados desta etapa

| Conteúdo | Valor atual validado |
|---|---|
| Mapa técnico | 600 segundos |
| Ataque Gaia | `physical:3`, `magical:3`, cooldown `2.0s` |
| Shape ataque Gaia | rectangle `size=(90,300)`, local offset `(0,0)` |
| Origem hitbox Gaia | offset direcional `160` |
| Hurtbox Goblin | capsule `radius=21`, `height=80`, offset `(0,0)` |
| Goblin fraquezas | `physical`, `magical`, bônus `50%` |
| Ataque Goblin | physical, raw `6`, intervalo `1.0s`, delay `0.75s` |
| Shape ataque Goblin | capsule `radius=25`, `height=88`, offset `(0,2)` |
| Hurtbox Gaia | capsule `radius=23`, `height=102`, offset `(0,41)` |
| Invencibilidade Gaia | `0.5s` após dano |

## Pendências futuras fora do fechamento atual

- movimentação orgânica de bando ao redor da Gaia;
- possível migração para tradução nativa Godot;
- proteção/assinatura/criptografia do save;
- balanceamento definitivo entre dano geral, físico e mágico;
- valores progressivos por stack de upgrade;
- mercadores, NPC raro, objetos quebráveis e caixas especiais;
- fragmentos, galeria, HUD lateral completa e Campanha;
- armas supremas, Rolls e Blocks;
- progressões completas e estatísticas ampliadas;
- novas Queens, inimigos e mapas.

## Regra de encerramento para todo módulo futuro

1. revisar blocos de scripts/scenes/resources alterados;
2. remover nodes, sinais, funções e arquivos sem uso;
3. extrair helpers/bases quando houver redundância real;
4. comentar as funções relevantes;
5. executar regressão completa;
6. atualizar docs e ADRs;
7. gerar contexto de atualização do Chat Core.

## Etapa 2R2-B — Movimento orgânico, knockback e blink overlay

Status: concluída funcionalmente.

Foram implementados:

- esbarrão físico configurável entre Goblins;
- correção visual para Goblins deslizarem sem inverter animação;
- knockback configurável por arma;
- knockback recebido configurável por inimigo;
- blink automático da Gaia como overlay em track superior do Spine.

A arquitetura modular Hitbox/Hurtbox foi preservada. BodyCollision continua sendo apenas colisão física/movimento e não causa dano.

O Goblin permanece um perseguidor simples. A organicidade do bando vem da resposta física entre inimigos e dos impulsos externos, não de IA de cerco.
