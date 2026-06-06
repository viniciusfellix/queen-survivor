# Tech Debt & Refatoração — Queen Survivor

Auditoria do código (`autoloads/`, `runtime/`, `gameplay/`, `visual/`, `ui/`, `definitions/`, `core/`, `tools/`) procurando: anti-padrões de Godot, sistemas redundantes com recursos nativos, e gargalos de performance. Itens em formato de checklist; cada um cita arquivo/linha aproximada, severidade e recomendação.

> Nenhum bug crítico de runtime foi encontrado. A arquitetura geral é boa (tipagem estática, serviços estáticos puros `DamageResolver`/`RewardResolver`/`LevelUpOptionService`, separação BodyCollision×Hitbox×Hurtbox respeitada, "gameplay decide / visual representa" cumprido). Os ganhos maiores estão em **pooling**, **eliminar reflexão nos hot paths** e **trocar 3 sistemas próprios por recursos nativos**.

---

## Ordem sugerida de ataque

1. Object pooling (inimigos, moedas, hitboxes de ataque, floating text) — maior impacto.
2. Cachear `RunState` / `is_gameplay_blocked` em O(1) — afeta todo frame de toda entidade.
3. `class_name PlayerController` / `EnemyBase` → remover `has_method`+`call` dos caminhos de dano.
4. `queue_redraw()` só com debug ligado.
5. RunHud por evento granular (sem polling, sem `get_debug_data`).
6. Migrar localização → tradução nativa; save → `ResourceSaver`; input → Input Map.
7. Validação data-driven (`@export_range`, validar strings contra catálogos).

---

## 1. Redundância com recursos nativos do Godot

- [x] **[Alta] Localização própria via JSON** — ~~`autoloads/LocalizationManager.gd`~~. **FEITO:** migrado para tradução nativa. `data/localization/translation.csv` (+ `.import`) substitui o `pt_br.json` (removido); os 80 `LocalizationManager.get_text(key)` viraram `tr(key)`; autoload removido de `project.godot` e registrado `[internationalization] locale/translations` + `locale/fallback="pt_BR"`; `App.gd` faz `TranslationServer.set_locale("pt_BR")` no boot. CSV com **6 idiomas** (pt_BR, en, es, zh, ja, ko) já reimportado pelo editor (`.translation` gerados e registrados). Locale padrão pt_BR via `App.gd`; trocar idioma = `TranslationServer.set_locale("en"/"es"/"zh"/"ja"/"ko")`. Futuro: ler a locale de `SaveData.settings`.
- [ ] **[Baixa] Save via JSON manual** — `autoloads/SaveManager.gd` (L66-88, L220-238) + `runtime/SaveData.gd` (L94-225). `SaveData` já é `Resource`, mas é serializado à mão (`to_dictionary`/`load_from_dictionary` + helpers `_safe_dictionary`/`_merge_basic_records`). Trocar por `ResourceSaver.save()` / `ResourceLoader.load()` (ou `var_to_str`/`str_to_var`). Remove ~130 linhas. **Pré-requisito:** marcar os campos de save de `SaveData` como `@export` (item abaixo).
- [ ] **[Média] `SaveData` sem `@export`** — `runtime/SaveData.gd` (L19-57). Campos persistentes são `var` puro; para serialização nativa de Resource precisam ser `@export` (com `##` tooltip).
- [x] **[Alta] Input actions criadas por código** — ~~`autoloads/InputManager.gd`~~. **FEITO:** as 9 actions (`move_left/right/up/down`, `dash`, `aim_left/right/up/down`) foram definidas no `[input]` do `project.godot` e as funções `_ensure_default_input_actions`/`_add_action_if_missing`/`_add_key_event` (+ chamada no `_ready`) removidas. Bindings: teclado WASD+setas e gamepad stick esquerdo (move), stick direito (aim, antes vazias), Espaço (dash). O InputManager agora só lê input via `Input.get_action_strength`.
- [ ] **[Média] Estado de input global por frame** — `autoloads/InputManager.gd` (L20-37, L66-89). Mantém `move_direction`/`aim_direction`/`dash_just_pressed` que só valem se `update_input_for_player()` rodar antes (acoplamento temporal; `is_action_just_pressed` pode ser perdido). Ler `Input` direto no `PlayerController` (`Input.get_vector(...)`, `Input.is_action_just_pressed("dash")`).
- [ ] **[Baixa] `App` duplica ProjectSettings** — `autoloads/App.gd`. `GAME_TITLE`/`GAME_VERSION` já existem em `application/config/name` e `.../version`. Ler de `ProjectSettings.get_setting(...)`.

---

## 2. Performance — hot paths (muitas entidades por frame)

- [ ] **[Alta] Sem object pooling** — `gameplay/drops/DropController.gd` (L134), `gameplay/spawners/EnemySpawner.gd` (L213), `gameplay/weapons/gaia/GaiaInitialWeaponController.gd` (L184, L217), `ui/world_feedback/WorldFeedbackLayer.gd` (L109-124) + `ui/world_feedback/FloatingCombatText.gd` (L131-133). Inimigos, moedas, hitboxes de ataque e textos flutuantes são `instantiate()`/`queue_free` continuamente → churn de GC e hitches. Implementar pooling (o `astra_spawner` já oferece pooling em outros pontos). No `FloatingCombatText`, resetar `animation_started` ao reusar.
- [ ] **[Alta] `load()` em runtime a cada spawn** — mesmos call-sites acima. `load(path)` por moeda/inimigo/ataque. Pré-carregar as `PackedScene` uma vez (`@export var ...: PackedScene` ou `preload`) e guardar em var.
- [ ] **[Alta] `is_gameplay_blocked()` resolvido por frame via grupo + reflexão** — `gameplay/run/RunQuery.gd` (L15-90). Faz `get_nodes_in_group("run_controller")` + `has_method` + `call("get_run_state")` **toda chamada**, e é chamado por frame em `EnemyBase` (L92), `EnemyAttackHitbox` (L59), `CoinDrop` (L72), `DirectionalAttackHitbox` (L86), `PlayerDashImpactArea` (L130), `EnemySpawner` (L109), `GaiaInitialWeaponController` (L105). Com 100+ entidades = milhares de buscas/frame. Expor o estado num autoload (`Run.is_gameplay_blocked` bool atualizado pelo RunController) e ler O(1).
- [ ] **[Alta] `queue_redraw()` por frame mesmo com debug desligado** — `gameplay/enemies/EnemyBase.gd` (L88, L99, L109, L122, L153, L258...), `gameplay/player/PlayerController.gd` (L88, L110...), `gameplay/drops/CoinDrop.gd` (L103). `_draw()` faz early-return se debug off, mas o `queue_redraw()` ainda marca o canvas dirty por frame em centenas de nós. Só chamar quando `draw_debug_*` estiver ligado.
- [ ] **[Alta] Falta `class_name` → reflexão nos caminhos de dano** — `gameplay/player/PlayerController.gd` e `gameplay/enemies/EnemyBase.gd` não declaram `class_name`, forçando `has_method`+`call` em `EnemyAttackHitbox` (L204), `DirectionalAttackHitbox` (L293, L307), `PlayerDashImpactArea` (L189, L203, L219), `GaiaInitialWeaponController` (L429, L829-857). Declarar `class_name PlayerController`/`EnemyBase` e usar cast tipado (`receiver as EnemyBase`) + acesso direto, removendo reflexão por hit.
- [ ] **[Alta] Contagem de inimigos vivos varre grupo** — `gameplay/spawners/EnemySpawner.gd` (L404-417, chamado em L204 e 3x no bloco de log L247/L253). `get_nodes_in_group("enemy")` + iteração por spawn. Manter contador incremental (++ no spawn, -- via signal `enemy_died`/`tree_exiting`).
- [ ] **[Média] Direção ao alvo recomputada 2x por inimigo/frame** — `gameplay/enemies/EnemyBase.gd` (L452-463, L877-884). `to_target.normalized()` em `_follow_target` e de novo em `_update_visual_state`. Calcular uma vez e reutilizar; aplicar throttle de heading (recalcular a cada ~0.2s escalonado por instância, manter última direção entre frames).
- [ ] **[Média] Body-bump loop com grupos + `call()` reflexivo** — `gameplay/enemies/EnemyBase.gd` (L512, L515-527, L630). `is_in_group("enemy")`/`is_in_group("player")`/`call("is_enemy_alive")` dentro do loop de colisões por frame. Trocar por cast de tipo (`collider is EnemyBase`) e acesso direto a `is_alive`/`body_bump_power`.
- [ ] **[Média] `get_overlapping_areas()` por frame** — `gameplay/combat/EnemyAttackHitbox.gd` (L177); também `PlayerDashImpactArea` (L142), `DirectionalAttackHitbox` (L266, vida curta). Aloca Array por frame por hitbox. Preferir reagir a `area_entered`/`area_exited` mantendo um set de hurtboxes e aplicar dano por timer.
- [ ] **[Média] `DamageComponentDefinition.new()` por hit** — `gameplay/combat/DamageResolver.gd` (L60-66, fallback de dano simples) + `Dictionary`/`breakdown` alocados por hit (L35-39). Calcular o fallback inline ou reusar componente estático; caminho rápido sem dicionário quando não há breakdown.
- [ ] **[Média] Strings de log formatadas mesmo com canal desligado** — generalizado: `EnemyBase.gd` (L230-250, L287-303), `PlayerController.gd` (L200), `DropController.gd` (L100, L155), `RunController.gd`, `GaiaInitialWeaponController.gd` (L165, L321), `visual/.../GoblinWarriorVisualController.gd` (L154-166). O chamador monta `String` `%`-formatada + `Dictionary` literal **antes** do logger decidir descartar. Guardar com `if DeveloperAuditLogger.is_channel_enabled(CANAL):` antes de formatar nos hot paths.
- [ ] **[Média] `DeveloperAuditLogger.write_entry` deep-copia metadata por entrada** — `autoloads/DeveloperAuditLogger.gd` (L70-108, `metadata.duplicate(true)` L100). Evitar `duplicate(true)` em log de combate/spawn; duplicar só na exportação.
- [ ] **[Baixa] `print_to_console` ligado em release** — `autoloads/DeveloperAuditLogger.gd` (L32). Condicionar a `OS.is_debug_build()`.
- [ ] **[Baixa] `SceneTreeTimer` por morte de inimigo** — `gameplay/enemies/EnemyBase.gd` (L309-310). Em hordas, muitos timers (e não respeitam pausa por default). Usar timer interno acumulado / pooling.
- [ ] **[Baixa] Cooldown signal emitido por frame** — `gameplay/weapons/gaia/GaiaInitialWeaponController.gd` (L101-139). `_emit_cooldown_update()` emite para a HUD todo frame. Emitir só quando o ratio mudar de forma perceptível.
- [ ] **[Baixa] Modificadores de coleta consultados 2x/frame por moeda** — `gameplay/drops/CoinDrop.gd` (L201-225). `call("get_drop_collection_modifiers")` (aloca dict) duas vezes por frame por moeda magnetizada. Buscar uma vez/frame ou cachear via signal de upgrade.
- [ ] **[Baixa] `EnemyAttackHitbox._update_receiver_cooldowns` aloca `.keys()` por frame** — `gameplay/combat/EnemyAttackHitbox.gd` (L235). `if receiver_cooldowns.is_empty(): return` antes de iterar.
- [ ] **[Baixa] Validadores de catálogo recriam Array literal por chamada** — `core/constants/DamageTypes.gd` (L49), `core/constants/UpgradeTypes.gd` (L81, L98). `damage_type in [...]` aloca toda chamada (no hot path de validação de dano). Extrair `const ALL_TYPES` (ou `Dictionary` para lookup O(1)).

---

## 3. Performance — UI / efeitos

- [ ] **[Alta] RunHud: polling + reescrita total por frame** — `ui/hud/RunHud.gd` (L135-142 `_process` chama `_refresh_all`; callbacks L468-499 também). `_refresh_all` (L171-184) puxa `get_debug_data()` do player e do run controller e reescreve **todos** os labels. Remover o polling de `_process`; cada callback de evento atualiza só o bloco correspondente usando os parâmetros que já recebe.
- [ ] **[Alta] DebugOverlay reconstrói tudo por frame** — `ui/debug/DebugOverlay.gd` (L97-172). Monta `Array[String]`, `get_nodes_in_group("player")`, `get_text` por seção e reescreve o label inteiro a cada frame. Adicionar `refresh_interval_seconds` (como o PrototypeToolsPanel já faz) e cachear títulos estáticos.
- [ ] **[Média] DebugOverlay sincroniza o link drawer por frame** — `ui/debug/DebugOverlay.gd` (L97-101, L439-466). `configure` do drawer todo frame sem mudança. Sincronizar só quando exports mudarem.
- [ ] **[Média] Visual de ataque usa `_process` para fade/lifetime** — `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd` (L79-87). Instância de vida curta (0.22s) com `_process` + `queue_free`. Trocar por `create_tween()` (fade em `modulate:a`) + `tween_callback(queue_free)`; idealmente poolar. Evitar `load()` do placeholder em runtime (L132-133) → `preload`.
- [ ] **[Baixa] DebugEnemyLinkDrawer redesenha a 60fps** — `ui/debug/DebugEnemyLinkDrawer.gd` (L47-51, L82-120). Throttle do redraw (linhas de debug não precisam de 60fps).
- [ ] **[Baixa] PrototypeToolsPanel recalcula layout a cada refresh** — `ui/debug/tools/PrototypeToolsPanel.gd` (L193). `_configure_layout` só precisa rodar no `_ready` + sinal `size_changed`.
- [ ] **[Baixa] LevelUpPanel usa `find_child` recursivo por card** — `ui/level_up/LevelUpPanel.gd` (L168-170, L287, L296). Cachear refs dos sub-nodes uma vez.
- [ ] **[Baixa] RunFeedbackLayer cria `Label.new()` por mensagem** — `ui/feedback/RunFeedbackLayer.gd` (L80-99). Pool pequeno se o feedback de moeda for frequente.
- [ ] **[Baixa] FloatingCombatText: pivot calculado antes do layout** — `ui/world_feedback/FloatingCombatText.gd` (L69, L80). `pivot_offset = size*0.5` pode usar size desatualizado. Recalcular após `resized`/`call_deferred`.

---

## 4. Anti-padrões e arquitetura

- [ ] **[Média] RunHud depende de `get_debug_data()`** — `ui/hud/RunHud.gd` (L421-457). Acopla a HUD a chaves internas de debug. Consumir os payloads do `GameEvents` (`run_xp_changed`, `run_coins_changed`, `run_timer_changed`, `weapon_cooldown_changed`, `player_damaged`). Reservar `get_debug_data` ao DebugOverlay.
- [ ] **[Média] Resolução de visual por nome de nó hardcoded + busca recursiva** — `gameplay/enemies/EnemyBase.gd` (L886-923, `"VisualRoot/GoblinWarriorVisual"` + `_find_node_with_method`) e `gameplay/player/PlayerController.gd` (L449 `"VisualRoot/GaiaVisual"`, L482, L499). Resolver só pelo `@export NodePath` já existente, com `push_error` se ausente.
- [ ] **[Média] Helpers de busca em grupo duplicados 5x** — `_find_first_node2d_in_group`/`_resolve_player`/`_resolve_target` copiados em `gameplay/camera/FollowCamera.gd` (L106), `EnemyBase.gd` (L941), `drops/CoinDrop.gd` (L183), `drops/DropController.gd` (L213), `spawners/EnemySpawner.gd` (L445). Extrair helper estático único (ex.: `SceneQuery.get_first_node2d_in_group`) ou expor o player via autoload. Idem `_find_node_with_method` (duplicado em EnemyBase e PlayerController).
- [ ] **[Média] Forward de upgrade para armas via grupo + `call()`** — `gameplay/player/PlayerController.gd` (L699, `get_nodes_in_group("player_weapon")` + `call("apply_run_upgrade")`). Manter `@export var weapons: Array[Node]`.
- [ ] **[Baixa] `get_nodes_in_group("player")[0]` hardcoded** — `gameplay/run/RunController.gd` (L565-571), `ui/hud/RunHud.gd` (L422). Referência exportada ou autoload.
- [ ] **[Baixa] Uso de node groups proibido pela convenção** — `ui/debug/DebugEnemyLinkDrawer.gd` (L96, L158), `core/debug/RuntimeTreeSnapshot.gd` (L104-118, L296-307). Código de debug; se os grupos não existirem em runtime, `build_group_summary` é código inútil — confirmar.
- [ ] **[Baixa] `int(get_instance_id()) % 2` como pseudo-aleatório de lado** — `gameplay/enemies/EnemyBase.gd` (L584, L697), `gameplay/player/PlayerDashImpactArea.gd` (L295). Guardar `var _lateral_sign` calculado uma vez em `_ready`.
- [ ] **[Baixa] `run_level_up_started(... options: Array)` não tipado** — `autoloads/GameEvents.gd` (L84). Tipar `Array[UpgradeDefinition]`.

---

## 5. Data-driven / Resources (validação e inspector)

- [ ] **[Média] `coin_drop_chance` sem clamp** — `definitions/EnemyDefinition.gd` (L66). É probabilidade → `@export_range(0.0, 1.0, 0.01)`.
- [ ] **[Média] `weak_damage_types`/`resistant_damage_types` strings livres** — `definitions/EnemyDefinition.gd` (L49-52). Validar contra `DamageTypes.is_valid_type()` em `is_valid_definition()` (ou `@export_flags`/enum).
- [ ] **[Média] `upgrade_type` string livre sem validação** — `definitions/UpgradeDefinition.gd` (L29-32, L53-58). Designer pode digitar tipo inexistente → upgrade aplica em silêncio. Criar `UpgradeTypes.is_valid_type()` (não existe; só `is_player_upgrade`/`is_weapon_upgrade`, e alguns tipos ficam órfãos) e usar no validador.
- [ ] **[Média] `impact_direction_mode` como `@export_enum` de strings** — `definitions/QueenDashDefinition.gd` (L75-76). Migrar para `enum` GDScript nativo (type-safe; o controller consumidor compara strings hoje).
- [ ] **[Baixa] `is_valid_definition()` fracas** — `definitions/EnemyDefinition.gd` (L161-162, só checa `id`) e `definitions/WeaponDefinition.gd` (L104-105, não valida `damage_type`/`base_damage`). Compor os helpers existentes (`has_valid_hurtbox_areas`, etc.) e validar HP/dano > 0.
- [ ] **[Baixa] Floats de balanceamento sem `@export_range`** — `definitions/EnemyDefinition.gd` (body_bump/slide/knockback), `QueenDashDefinition.gd` (L25-83), `CoinDropDefinition.gd` (magnet/collect radius), `SpawnTimelineEntryDefinition.gd`. Adicionar ranges sensatos (note a inconsistência: os campos `*_influence`/`*_weight` já usam range).
- [ ] **[Baixa] Animação específica da Gaia como default em resource genérico** — `definitions/QueenDashDefinition.gd` (L120, L132: `"Dash1_Pose3"`, `3.0`). Default vazio num resource de Queen genérico.
- [ ] **[Baixa] `GameplayStateTypes` poderia ser `enum`** — `core/constants/GameplayStateTypes.gd`. Estado runtime não serializado em `.tres` é bom candidato a `enum` nativo (verificar se é exposto a designers). `DamageTypes`/`UpgradeTypes` ficam como string por irem para `.tres` — trade-off legítimo, não mudar.

---

## 6. Código morto / ferramentas

- [ ] **[Média] Formato de shape "D" possivelmente abandonado** — `definitions/CombatShapeDefinition.gd` (L196-240: `build_d_shape_points`/`create_d_shape`) + tool `tools/create_gaia_d_attack_area.gd`. Comentários marcam como "teste futuro / decisão a tomar". Só usados pelo tool one-shot. Decidir: oficializar ou remover ambos.
- [ ] **[Baixa] `export_project_structure.gd` usa tipagem inferida (`:=`)** — `tools/audit/export_project_structure.gd` (vários). Inconsistente com a regra de tipagem explícita; confirmar se ainda é usado.
- [ ] **[Baixa] Subclasses triviais de adapter Spine** — `visual/characters/gaia/GaiaSpineAdapter.gd`, `visual/enemies/goblin_warrior/GoblinWarriorSpineAdapter.gd`. Só fazem override de nome de log / flag. Expor `@export var adapter_log_name` + `@export var publish_animation_changed` na base e eliminar as subclasses.
- [ ] **[Baixa] Comentário obsoleto sobre typo** — `ui/world_feedback/WorldFeedbackLayer.gd` (L9-12). Arquivo já está com nome correto; remover.

---

## 7. Redundância de código (extrair para base/helper)

- [ ] **[Média] `play_damage_flash` duplicado** — `visual/characters/gaia/GaiaVisualController.gd` (L139-156) vs `visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd` (L121-152). Mesma lógica (matar tween → set modulate → tween de volta). Subir `_play_modulate_flash(color, hold, duration)` para `SpineVisualControllerBase`.
- [ ] **[Média] LevelUpPanel hardcoded para 3 cards** — `ui/level_up/LevelUpPanel.gd` (L73-80, L121-123, L304-311). Trio de callbacks/aplicações idênticas. Iterar sobre `Array[Button]` com `index` via `bind`; suporta N opções.
- [ ] **[Baixa] Adapter base: blocos `_try_play_*`/`_try_clear_*` repetem resolução de `animation_state`** — `visual/spine/SpineAnimationAdapterBase.gd` (L200-214, L234-245). Extrair `_get_animation_state() -> Object`.
- [ ] **[Baixa] Adapter base varre `get_property_list()` no caminho quente** — `visual/spine/SpineAnimationAdapterBase.gd` (L278-287). Cachear o nome do método/propriedade de time scale na primeira resolução.

---

## 8. Organização / convenções (rápidos)

- [ ] **[Baixa] Exports sem tooltip `##`** — `visual/characters/gaia/GaiaVisualController.gd` (L5-48). O Goblin controller tem; este não. Adicionar `##` em inglês (rule 6).
- [ ] **[Baixa] Vars não-exportadas sem comentário PT** — `visual/characters/gaia/GaiaVisualController.gd` (L46-54) (rule 9).
- [ ] **[Baixa] `##` usado como comentário inline** — `ui/feedback/RunFeedbackLayer.gd` (L88) deveria ser `#`.
- [ ] **[Baixa] Tipagem implícita** — `autoloads/LocalizationManager.gd` (L54, `var parsed = JSON.parse_string`).
- [ ] **[Baixa] `RunState`/`PlayerRuntimeState` são `Resource` mas estado runtime** — `runtime/RunState.gd`, `runtime/PlayerRuntimeState.gd`. Sem `@export` e nunca salvos → poderiam ser `RefCounted`. Decisão de coerência. Também: curva de XP hardcoded em `RunState.gd` (L225-226, `10 + (level-1)*5`) poderia virar resource configurável.
