# PR8 Pooling Lifecycle Audit

## Objetivo

Auditar o lifecycle dos objetos de alto volume do projeto e padronizar ajustes pequenos de pooling/reuso onde o `PoolManager` já existe e o reset é seguro.

## Sistemas inspecionados

- `autoloads/PoolManager.gd`
- `gameplay/drops/DropController.gd`
- `gameplay/drops/CoinDrop.gd`
- `gameplay/drops/CoinDrop.tscn`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.tscn`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`
- `gameplay/player/PlayerDashImpactArea.gd`
- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/spawners/EnemySpawner.gd`
- `gameplay/enemies/EnemyBase.gd`
- `ui/world_feedback/FloatingCombatText.gd`
- `ui/world_feedback/WorldFeedbackLayer.gd`

## Objetos de alto volume avaliados

- inimigos (`EnemyBase` via `EnemySpawner`)
- moedas (`CoinDrop`)
- hitboxes temporárias da arma da Gaia (`DirectionalAttackHitbox`)
- visual temporário da arma da Gaia (`GaiaAttackVisualController`)
- textos flutuantes (`FloatingCombatText`)
- hitbox de ataque inimigo (`EnemyAttackHitbox`)
- área de impacto do dash (`PlayerDashImpactArea`)

## Classificação por objeto

### Já pooled

- `CoinDrop`
- `DirectionalAttackHitbox`
- visual do ataque da Gaia
- `EnemyBase` via `EnemySpawner`
- `FloatingCombatText`

### Não precisa pooling agora

- `PlayerDashImpactArea`
  - fica anexada ao player;
  - não é criada/destruída por dash;
  - o importante aqui é ativar/desativar shapes e monitoring, o que já acontece.

- `EnemyAttackHitbox`
  - fica anexada ao inimigo;
  - não é criada/destruída por hit;
  - o custo maior aqui é lifecycle das shapes runtime, não instantiate do node inteiro.

### Pooling futuro

- pooling/caching mais fino das `CollisionShape2D` runtime em:
  - `DirectionalAttackHitbox`
  - `EnemyAttackHitbox`
  - `PlayerDashImpactArea`
  - `HurtboxComponent`

Isso pode esperar porque o node principal já está sendo reutilizado e a mudança agora seria mais invasiva.

### Precisa pooling agora

Nenhum objeto novo entrou nessa categoria nesta PR, porque os objetos mais frequentes já usam `PoolManager`.

## Onde já existe pooling funcional

### `PoolManager`

O `PoolManager` já fornece:

- cache de `PackedScene` por caminho;
- fila de instâncias livres por cena;
- `spawn()` / `spawn_path()`;
- `despawn()`;
- hooks opcionais:
  - `_on_pool_acquire()`
  - `_on_pool_release()`

### Moeda

- `DropController` usa `PoolManager.spawn_path()` para `CoinDrop`;
- `CoinDrop` devolve via `PoolManager.despawn(self)`.

### Ataque da Gaia

- `GaiaInitialWeaponController` usa `PoolManager.spawn_path()` para:
  - visual do ataque;
  - `DirectionalAttackHitbox`.

### Inimigos

- `EnemySpawner` usa `PoolManager.spawn_path()` para `EnemyBase`;
- também faz `prewarm_path()` no `_ready()`.

### Textos flutuantes

- `WorldFeedbackLayer` usa `PoolManager.spawn()` para `FloatingCombatText`;
- `FloatingCombatText` devolve via `PoolManager.despawn(self)`.

## Onde ainda há instantiate()/queue_free()

### Instantiate aceitável fora do hot path principal

- `Main.gd`
- `RunScene.gd`
- `TestGaiaScene.gd`

Esses pontos são bootstrap/composição, não volume alto por frame.

### Queue free ainda presente

- `PoolManager` usa `queue_free()` como fallback seguro para nodes não poolados;
- `DirectionalAttackHitbox`, `EnemyAttackHitbox`, `PlayerDashImpactArea` e `HurtboxComponent` ainda fazem `queue_free()` de `CollisionShape2D` runtime antigas ao reconstruir shapes;
- `RunFeedbackLayer` ainda usa labels temporárias com `queue_free()`, mas isso não foi tratado nesta PR porque não está no mesmo volume crítico de moeda/inimigo/hitbox;
- timers `SceneTreeTimer` continuam sendo usados para atrasos de morte/resultado e não são problema de pooling por si só.

## Ajustes pequenos feitos nesta PR

### `CoinDrop`

- passou a desligar explicitamente:
  - `set_physics_process(false)`
  - `MagnetArea.monitoring`
  - `CollectArea.monitoring`
  - `CollisionShape2D.disabled`
  ao voltar para o pool;
- passa a religar esses estados no acquire;
- continua zerando flags e velocidade no acquire.

### `DirectionalAttackHitbox`

- passa a ligar/desligar também `set_physics_process()` junto com `monitoring`;
- continua desligando shapes ao sair de uso;
- ao terminar `lifetime`, desativa a hitbox antes do `despawn`.

### `EnemyAttackHitbox`

- passa a ligar/desligar `set_physics_process()` junto com `monitoring`;
- continua desligando shapes quando inativa.

### `GaiaAttackVisualController`

- ganhou `_on_pool_release()` explícito;
- desliga `_process`, esconde o node e reseta alpha ao hibernar;
- volta a ligar `_process` no acquire/setup.

### `FloatingCombatText`

- agora guarda referências para tweens ativos;
- mata tweens no acquire/release;
- evita reuso com tween velho, fade velho ou callback pendurado;
- reseta visibilidade, alpha e escala ao voltar para o pool.

## Riscos de performance encontrados

- construção e destruição de `CollisionShape2D` runtime ainda existe em hitboxes/hurtboxes;
- `EnemyBase` ainda cria `SceneTreeTimer` por morte, mas isso é custo baixo comparado ao spawn/despawn em massa;
- `RunFeedbackLayer` ainda usa `queue_free()` para labels temporárias e pode merecer revisão futura se o volume crescer;
- buscas por grupo ainda existem em alguns pontos de setup/resolução, mas não apareceram como problema crítico de frame a frame nesta auditoria.

## Riscos de bug ao reutilizar nodes

- tween antigo persistindo no texto flutuante;
- área de coleta/magnetismo continuar monitorando após despawn;
- hitbox continuar com `_physics_process()` ligado mesmo inativa;
- visual temporário voltar do pool invisível ou com alpha antigo;
- listas/flags de hit permanecerem sujas entre reusos.

## Contrato recomendado para pooled objects

### Acquire

- restaurar visibilidade;
- resetar alpha/modulate/scale/rotation;
- limpar arrays de receivers já atingidos;
- reativar `monitoring`;
- reativar `set_process()` / `set_physics_process()` quando necessário;
- reabilitar `CollisionShape2D.disabled = false` quando o objeto estiver ativo.

### Release

- desligar `monitoring`;
- desligar `set_process()` / `set_physics_process()` quando o objeto estiver inativo;
- marcar `CollisionShape2D.disabled = true`;
- matar tweens e animações runtime;
- limpar velocidade/flags/estado transitório.

## Objetos que devem ser refatorados em PR futura

- cache/reuso de `CollisionShape2D` runtime em:
  - `DirectionalAttackHitbox`
  - `EnemyAttackHitbox`
  - `PlayerDashImpactArea`
  - `HurtboxComponent`
- `RunFeedbackLayer` para evitar `queue_free()` frequente se o volume de mensagens crescer;
- revisão de pooling de efeitos visuais futuros e projéteis futuros;
- possível auditoria específica do lifecycle de death timers em inimigos se houver problemas observados em playtest longo.

## Testes manuais necessários

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar o jogo pelo botão principal/play.
4. Confirmar que a cena carregada é `RunScene`.
5. Matar vários Goblins e gerar moedas.
6. Confirmar que moedas nascem, magnetizam, coletam e somam no HUD.
7. Confirmar que moedas coletadas não reaparecem com estado sujo.
8. Confirmar que ataque da Gaia continua acertando Goblins.
9. Confirmar que a hitbox da Gaia não atinge o mesmo Goblin duas vezes pela mesma instância.
10. Confirmar que dash continua funcionando.
11. Confirmar que dash impacta/empurra Goblins, se configurado.
12. Confirmar que Goblin continua causando dano.
13. Confirmar que XP entra direto.
14. Confirmar que level-up abre e upgrades funcionam.
15. Confirmar vitória/derrota/result/save.
16. Se possível, testar situação com muitas moedas e ataques por alguns minutos.
17. Confirmar que não há warnings/erros novos.
18. Confirmar que debug/logs verbosos não ficaram ligados por padrão.

## Próximos passos

1. validar manualmente os objetos já pooled em sessão longa;
2. decidir se `RunFeedbackLayer` merece pooling próprio;
3. auditar pooling de projéteis quando esse domínio existir;
4. avaliar reuso de shapes runtime apenas se profiling indicar custo real.
