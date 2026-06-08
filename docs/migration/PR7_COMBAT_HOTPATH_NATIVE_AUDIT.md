# PR7 Combat Hotpath Native Audit

## Objetivo da PR

Auditar o hot path de combate/dano do projeto e sanear pontos pequenos onde a detecção ainda fazia trabalho desnecessário no frame loop, mantendo a arquitetura centrada em `Area2D`, `CollisionShape2D`, `layers/masks` e receivers explícitos.

## Sistemas inspecionados

- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.tscn`
- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/player/PlayerDashImpactArea.gd`
- `gameplay/combat/HurtboxComponent.gd`
- `gameplay/player/PlayerGaia.tscn`
- `gameplay/enemies/EnemyBase.tscn`
- `gameplay/combat/DamagePayload.gd`
- `gameplay/combat/DamageResolver.gd`
- `gameplay/player/PlayerController.gd`
- `gameplay/enemies/EnemyBase.gd`
- `definitions/EnemyDefinition.gd`
- `definitions/WeaponDefinition.gd`
- `data/enemies/enemy_chaser_basic.tres`

## Scripts e cenas no hot path de combate

Os arquivos mais diretamente envolvidos no dano em runtime são:

- `DirectionalAttackHitbox.gd`
- `EnemyAttackHitbox.gd`
- `PlayerDashImpactArea.gd`
- `HurtboxComponent.gd`
- `PlayerController.gd`
- `EnemyBase.gd`
- `DamagePayload.gd`
- `DamageResolver.gd`

## Sistemas que já usam Area2D corretamente

### Ataque da Gaia

- `DirectionalAttackHitbox` já é `Area2D`;
- usa `CollisionShape2D` runtime a partir de `AttackAreaDefinition`;
- detecta `HurtboxComponent` por `area_entered`;
- passa dano por `DamagePayload`;
- receiver final do inimigo continua em `EnemyBase.receive_damage()`.

### Ataque do Goblin

- `EnemyAttackHitbox` já é `Area2D`;
- usa `CollisionShape2D` runtime a partir de `EnemyAttackDefinition`;
- detecta `PlayerHurtbox` (`HurtboxComponent`);
- envia `DamagePayload` para `PlayerController.receive_damage()`;
- `BodyCollision` continua separada da fonte de dano.

### Dash da Gaia

- `PlayerDashImpactArea` já é `Area2D`;
- usa `CollisionShape2D` runtime a partir de `QueenDashDefinition`;
- detecta `EnemyHurtbox`;
- dano e knockback passam por receiver do inimigo;
- não usa `BodyCollision` como dano.

### Hurtboxes

- `HurtboxComponent` já é `Area2D`;
- constrói `CollisionShape2D` runtime a partir de `HurtboxAreaDefinition`;
- expõe `get_damage_receiver()` e `can_receive_damage()`;
- mantém detecção separada da matemática de dano.

## Sistemas que ainda usavam polling ou trabalho manual

### Antes dos ajustes desta PR

- `DirectionalAttackHitbox` varria `get_overlapping_areas()` em todo `_physics_process()` durante a vida da hitbox;
- `PlayerDashImpactArea` varria `get_overlapping_areas()` em todo `_physics_process()` enquanto o dash estava ativo;
- `EnemyAttackHitbox` varria `get_overlapping_areas()` em todo `_physics_process()` para manter dano periódico;
- `DirectionalAttackHitbox.tscn` mantinha `draw_debug_hitbox = true` por padrão;
- `EnemyAttackHitbox` mantinha `log_successful_hits = true` por padrão;
- `PlayerGaia.tscn` e `EnemyBase.tscn` mantinham `log_configuration = true` em áreas de combate por padrão.

### Ainda presentes, mas fora do escopo desta PR

- `EnemyBase` resolve o alvo por grupo (`get_nodes_in_group`) quando necessário, mas não a cada frame se `target_node` já estiver resolvido;
- `EnemySpawner` usa cálculos de distância para regras de spawn, o que é aceitável no domínio de spawn e não no hot path de dano;
- `PlayerController` procura armas por grupo ao aplicar upgrade, fora do hot path de combate por frame.

## Layers e masks encontradas

### Player

- `PlayerGaia` body:
  - `collision_layer = 2`
  - `collision_mask = 5`
- `PlayerHurtbox`:
  - `collision_layer_number = 7`

### Inimigo

- `EnemyBase` body:
  - `collision_layer = 4`
  - `collision_mask = 7`
- `EnemyAttackHitbox`:
  - `collision_layer_number = 6`
  - `target_hurtbox_layer_number = 7`
- `EnemyHurtbox`:
  - `collision_layer_number = 5`

### Ataques ofensivos da Gaia

- `DirectionalAttackHitbox`:
  - `attack_collision_layer_number = 4`
  - `target_hurtbox_mask_number = 5`

### Dash ofensivo da Gaia

- `PlayerDashImpactArea`:
  - `impact_collision_layer_number = 4`
  - `enemy_hurtbox_mask_number = 5`

## Fluxo atual do dano da Gaia

`GaiaInitialWeaponController`
-> instancia `DirectionalAttackHitbox`
-> `DirectionalAttackHitbox` detecta `EnemyHurtbox`
-> cria `DamagePayload`
-> chama `EnemyBase.receive_damage(payload)`
-> `DamageResolver.calculate_enemy_damage(...)`
-> `EnemyBase` aplica HP, eventos e morte

## Fluxo atual do dano do Goblin

`EnemyBase`
-> configura `ContactAttackHitbox`
-> `EnemyAttackHitbox` detecta `PlayerHurtbox`
-> respeita `start_delay_seconds` e `hit_interval_seconds`
-> cria `DamagePayload`
-> chama `PlayerController.receive_damage(payload)`
-> `DamageResolver.calculate_received_damage(...)`
-> `PlayerController` aplica HP, invulnerabilidade, feedback e morte

## Fluxo atual do dano do dash

`PlayerController`
-> ativa `PlayerDashImpactArea`
-> `PlayerDashImpactArea` detecta `EnemyHurtbox`
-> aplica dano opcional por `DamagePayload`
-> aplica knockback opcional por `EnemyBase.apply_hit_knockback(...)`

## BodyCollision ainda causa dano?

Não.

Nesta base inspecionada:

- `BodyCollision` do player e do inimigo é usada para física/movimento;
- dano do inimigo vem de `EnemyAttackHitbox`;
- dano da Gaia vem de `DirectionalAttackHitbox`;
- dano do dash vem de `PlayerDashImpactArea`.

## Ajustes pequenos feitos nesta PR

1. `DirectionalAttackHitbox`
   - deixou de varrer overlaps a cada `_physics_process()`;
   - agora usa `area_entered` + uma leitura deferida única dos overlaps ao ativar;
   - passou a ativar/desativar `monitoring` e `CollisionShape2D.disabled` explicitamente;
   - ganhou `log_successful_hits = false` por padrão.

2. `PlayerDashImpactArea`
   - deixou de varrer overlaps a cada `_physics_process()`;
   - continua usando `area_entered` e uma leitura deferida única ao ativar o dash.

3. `EnemyAttackHitbox`
   - manteve dano periódico, mas trocou `get_overlapping_areas()` por frame por um conjunto rastreado com `area_entered/area_exited`;
   - continua respeitando cooldown por receiver;
   - agora mantém `CollisionShape2D` desabilitada enquanto a área não está ativa;
   - `log_successful_hits` passou para `false` por padrão.

4. Debug/logs por padrão
   - `DirectionalAttackHitbox.tscn` não desenha hitbox de debug por padrão;
   - `PlayerGaia.tscn` e `EnemyBase.tscn` não ligam `log_configuration` por padrão nas áreas de combate.

## Ajustes adiados

- `DirectionalAttackHitbox`, `EnemyAttackHitbox` e `PlayerDashImpactArea` ainda constroem `CollisionShape2D` runtime a cada `setup()`. Isso funciona, mas uma futura PR pode avaliar cache/reuso por pool quando houver evidência real de custo;
- `PlayerController` e `EnemyBase` ainda concentram receiver + telemetria + logs. Funciona, mas uma PR futura pode reduzir custo de logging no caminho quente sem tocar na regra;
- não foi criada uma arquitetura genérica nova de ataque/projétil nesta PR;
- não foi alterado o tracking de alvo do inimigo além da auditoria.

## Riscos de performance encontrados

- o principal risco encontrado era o polling repetido de overlaps nas hitboxes ofensivas;
- logs de combate e configuração estavam mais verbosos do que o ideal por padrão em alguns pontos;
- `EnemyBase` ainda tem custo de movimento/slide/body bump próprio de horda, mas isso está no domínio de locomoção, não no pipeline de dano.

## Recomendações para PR futura

1. avaliar pooling/reuso mais profundo para shapes runtime se a contagem de ataques simultâneos crescer muito;
2. revisar volume de `DeveloperAuditLogger` no caminho quente de dano recebido/aplicado;
3. auditar projéteis futuros para seguir o mesmo contrato:
   - `Area2D`
   - `CollisionShape2D`
   - `HurtboxComponent`
   - `DamagePayload`
   - `DamageResolver`
4. manter `BodyCollision` estritamente fora de dano.

## Testes manuais necessários

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar o jogo pelo botão principal/play.
4. Confirmar que a cena carregada é `RunScene`.
5. Testar ataque da Gaia:
   - ataque sai;
   - hitbox acerta Goblin;
   - Goblin recebe dano;
   - dano híbrido continua funcionando;
   - fraqueza física/mágica continua funcionando;
   - Goblin morre.
6. Testar ataque do Goblin:
   - Goblin persegue;
   - Goblin causa dano na Gaia;
   - dano respeita defesa;
   - invulnerabilidade pós-dano funciona.
7. Testar dash:
   - dash funciona;
   - dash impacta Goblin se configurado;
   - dash não causa dano via `BodyCollision`;
   - knockback funciona.
8. Testar sistemas não tocados:
   - moeda dropa;
   - moeda magnetiza/coleta;
   - XP entra direto;
   - level-up abre;
   - upgrades funcionam;
   - HUD aparece;
   - vitória/derrota/result/save funcionam.
9. Confirmar console sem erro novo.
10. Confirmar que debug draw/logs verbosos não ficaram ligados por padrão.
