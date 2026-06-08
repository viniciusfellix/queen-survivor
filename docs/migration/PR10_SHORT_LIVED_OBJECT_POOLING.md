# PR10 - Short-Lived Object Pooling

## Objetivo da PR

Fortalecer o pooling de objetos temporarios de vida curta e potencial alto volume, sem alterar gameplay, balanceamento, dano, economia, UI funcional ou fluxo de runtime.

## Por que isso importa

Queen Survivors e um survivor-like/bullet hell. Em jogo real, a run pode acumular muitos ataques, visuais temporarios e textos flutuantes na tela. Mesmo com `PoolManager` ja existente, o risco principal continua sendo **estado sujo entre reutilizacoes**:

- hitboxes reaproveitadas carregando alvos antigos;
- visuais reaproveitados com alpha/rotacao/escala errados;
- textos flutuantes reaproveitados com tween antigo, texto antigo ou fade residual.

Esta PR nao cria um novo sistema de pooling. Ela endurece o contrato de reuso dos objetos prioritarios que ja estavam no `PoolManager`.

## Objetos inspecionados

- `autoloads/PoolManager.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.tscn`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`
- `visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn`
- `ui/world_feedback/FloatingCombatText.gd`
- `ui/world_feedback/FloatingCombatText.tscn`
- `ui/world_feedback/WorldFeedbackLayer.gd`

## Estado encontrado

Os tres objetos prioritarios ja estavam usando `PoolManager` antes desta PR:

- `DirectionalAttackHitbox` ja era adquirida via `PoolManager.spawn_path(...)` em `GaiaInitialWeaponController.gd` e devolvida por `PoolManager.despawn(self)`.
- `GaiaAttackVisualController` ja era adquirido via `PoolManager.spawn_path(...)` e devolvido por `PoolManager.despawn(self)`.
- `FloatingCombatText` ja era adquirido via `PoolManager.spawn(...)` em `WorldFeedbackLayer.gd` e devolvido por `PoolManager.despawn(self)`.

Portanto, o foco da PR foi **sanear lifecycle e reset**, nao introduzir pooling do zero.

## Objetos migrados ou saneados nesta PR

### 1. DirectionalAttackHitbox

Mantida como objeto pooled.

Ajustes feitos:

- adicionado hook `_on_pool_release()`;
- limpeza explicita de:
  - `source_node`;
  - `attack_direction`;
  - `already_hit_instance_ids`;
  - `damage_components`;
  - `attack_areas`;
  - `elapsed_seconds`;
  - `is_configured`;
- garantia de desativacao de `monitoring`/`physics_process` via `_set_hitbox_active(false)` no acquire e no release;
- limpeza de shapes runtime nao usados entre reutilizacoes;
- reutilizacao dos `CollisionShape2D` internos da hitbox, evitando `queue_free()`/`new()` para os shapes do mesmo node pooled a cada ataque;
- limpeza explicita da lista de inimigos ja atingidos no `setup()`.

### 2. GaiaAttackVisualController

Mantido como objeto pooled.

Ajustes feitos:

- reset explicito no acquire/release de:
  - `elapsed_seconds`;
  - `attack_direction`;
  - `rotation`;
  - `scale`;
  - `modulate`;
  - `visible`;
  - `process`.

Isso evita reaproveitar visual com alpha residual, escala residual ou orientacao antiga.

### 3. FloatingCombatText

Mantido como objeto pooled.

Ajustes feitos:

- reforco do reset no acquire/release de:
  - `text`;
  - `visible`;
  - `self_modulate`;
  - `modulate`;
  - `scale`;
  - `pivot_offset`;
  - `animation_started`;
- kill explicito de tweens ativos antes de reusar ou hibernar.

Isso evita texto reaparecendo com tween anterior, alpha residual ou conteudo antigo.

## Objetos deixados para pooling futuro

Nenhum dos tres objetos prioritarios ficou bloqueado nesta PR porque todos ja usavam `PoolManager` de forma compativel.

Fora do escopo desta PR e mantidos para etapa futura:

- pooling de inimigos (`EnemyBase` / `EnemySpawner`) como evolucao mais ampla;
- `EnemyAttackHitbox`, por estar acoplada ao lifecycle do inimigo;
- `PlayerDashImpactArea`, por ser volume mais baixo;
- projeteis futuros e outros efeitos visuais ainda nao priorizados.

## Contrato de setup / activate / deactivate

O projeto ja usa um contrato distribuido entre `PoolManager`, `setup()` e hooks opcionais:

1. `PoolManager.spawn(...)` / `spawn_path(...)`
   - readiciona o node na arvore;
   - chama `_on_pool_acquire()` quando existir.

2. `setup(...)`
   - reaplica dados do uso atual;
   - redefine estado runtime;
   - reativa processamento/monitoring quando necessario.

3. `PoolManager.despawn(self)`
   - chama `_on_pool_release()` quando existir;
   - remove o node da arvore e o devolve para a fila.

Nesta PR, esse contrato ficou mais explicito para os objetos de vida curta:

- `DirectionalAttackHitbox`
  - acquire: limpar hits e desativar shapes;
  - setup: configurar dano, areas, lifetime e reativar;
  - release: desligar monitoring/process e limpar estado sensivel.

- `GaiaAttackVisualController`
  - acquire: restaurar visibilidade e estado visual base;
  - setup: aplicar direcao, lifetime e escala;
  - release: parar processamento e zerar estado visual.

- `FloatingCombatText`
  - acquire: matar tweens e restaurar estado base;
  - setup: aplicar texto/cor e iniciar animacao;
  - release: matar tweens e ocultar o label limpo.

## Como o estado sujo foi evitado

- limpeza de arrays/dicionarios de hit na `DirectionalAttackHitbox`;
- desligamento de `monitoring` e `physics_process` quando a hitbox fica inativa;
- limpeza de shapes runtime nao utilizados em reuso;
- reset de `modulate`, `scale`, `rotation` e `visible` no visual temporario;
- kill de tweens ativos no `FloatingCombatText`;
- reset de `text`, `animation_started`, `self_modulate` e `pivot_offset` no texto flutuante.

## Arquivos alterados

- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`
- `ui/world_feedback/FloatingCombatText.gd`

## Arquivos criados

- `docs/migration/PR10_SHORT_LIVED_OBJECT_POOLING.md`

## Por que gameplay e balanceamento nao mudaram

Esta PR nao altera:

- dano;
- cooldown;
- lifetime configurado de ataque/visual/texto;
- knockback;
- area de ataque;
- hit_once_per_enemy;
- XP;
- moeda;
- save;
- resultado;
- UI funcional fora do lifecycle do texto flutuante.

O comportamento percebido pelo jogador deve continuar o mesmo; a diferenca esta apenas na seguranca do reuso interno.

## Testes manuais necessarios

1. Abrir o projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar o jogo pelo botao principal/play.
4. Confirmar que a cena carregada e `RunScene`.
5. Testar ataque da Gaia repetidas vezes:
   - visual aparece;
   - hitbox acerta;
   - dano hibrido continua;
   - Goblin morre;
   - nao ha hit duplicado indevido.
6. Testar por alguns minutos com varios Goblins:
   - ataques continuam funcionando;
   - nao ha erro de objeto reutilizado;
   - nao ha hitbox presa no mapa;
   - nao ha visual preso no mapa.
7. Tomar dano com a Gaia:
   - `FloatingCombatText` aparece;
   - animacao continua correta;
   - texto desaparece;
   - textos reutilizados nao voltam com cor/escala/texto errados.
8. Testar dash, moeda, XP, level-up, upgrades, vitoria, derrota, result e save.
9. Confirmar console sem erro novo.

## Riscos conhecidos

- `DirectionalAttackHitbox` ainda recria `Shape2D` runtime por configuracao, embora agora reutilize os `CollisionShape2D` do node pooled. Isso ja reduz churn de nodes, mas pooling de shapes em si nao foi introduzido nesta PR.
- O `FloatingCombatText` continua usando tweens por instancia, o que e aceitavel neste escopo; o saneamento aqui foi evitar vazamento de tween entre reusos.

## Proximos passos esperados

1. Aplicar o mesmo endurecimento de lifecycle a outros objetos temporarios quando necessario.
2. Avaliar prewarm para cenas de ataque/feedback, se profiling indicar hitch inicial.
3. Continuar evitando pooling prematuro em objetos de baixo volume ou com reset ambíguo.
