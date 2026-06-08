# Queen Survivors - Documentacao Tecnica do Modulo 1

**Engine:** Godot 4.6.1 com Spine  
**Plataforma inicial:** PC  
**Cena oficial atual da run:** `res://scenes/run/RunScene.tscn`  
**Cena tecnica legada de referencia:** `res://gameplay/test/TestGaiaScene.tscn`

## Objetivo desta pasta

Esta pasta documenta o estado tecnico atual do projeto depois das PRs de migracao arquitetural e otimizacao. O objetivo e ajudar novos desenvolvedores a entender a base real de runtime, os contratos de gameplay, as ferramentas tecnicas e os pontos de manutencao.

## Ordem de leitura recomendada

1. `00_project/module_1_status.md`
2. `00_project/glossary.md`
3. `01_architecture/scene_architecture.md`
4. `01_architecture/collision_layers_and_combat_shapes.md`
5. `02_lifecycles/run_lifecycle.md`
6. `03_domains/combat_damage/damage_domain.md`
7. `05_game_design/README_GAME_DESIGN.md`
8. `06_reference/file_responsibilities.md`
9. `07_debug_audit/README_DEBUG_AUDIT.md`
10. `08_testing/regression_module_1.md`

## Estado oficial atual

- `RunScene` e a composition root oficial da run.
- `TestGaiaScene` permanece apenas como referencia tecnica temporaria.
- `DebugRoot` concentra ferramentas dev-only como `DebugOverlay` e `PrototypeToolsPanel`.
- O combate atual usa `Area2D`, `CollisionShape2D`, layers/masks e signals nativos.
- `BodyCollision` e apenas fisica/movimento; nao causa dano.
- `DamageResolver` calcula dano; nao detecta colisao.
- `CoinDrop` usa `Area2D` + signals e so processa fisica quando precisa magnetizar.
- Entidades de alto volume usam `PoolManager` no caminho quente.
- Textos visiveis usam localizacao nativa Godot via `tr(key)` e `data/localization/translation.csv`.

## Regras tecnicas importantes

- Nao voltar a usar dano por distancia manual para o sistema atual.
- Nao usar `BodyCollision` como fonte de dano.
- Nao reintroduzir `LocalizationManager` ou JSON proprio de traducao.
- Nao reintroduzir polling continuo para moeda, hitbox ou hurtbox quando o fluxo atual ja usa signals/Area2D.
- Nao voltar a `instantiate()/queue_free()` direto para entidades de alta rotacao que ja foram migradas para pooling.

## Combate oficial atual

```text
GaiaInitialWeaponController
-> DirectionalAttackHitbox <Area2D>
-> HurtboxComponent <Area2D>
-> EnemyBase.receive_damage()
-> DamageResolver
```

```text
EnemyBase / ContactAttackHitbox <Area2D>
-> PlayerHurtbox <Area2D>
-> PlayerController.receive_damage()
-> DamageResolver
```

## Navegacao rapida

| Necessidade | Documento |
|---|---|
| Alterar a arma da Gaia | `05_game_design/edit_gaia_weapon.md` |
| Alterar o Goblin | `05_game_design/edit_goblin.md` |
| Criar inimigo | `05_game_design/create_new_enemy.md` |
| Criar arma ou ataque | `05_game_design/create_new_weapon_or_attack.md` |
| Criar upgrade | `05_game_design/create_new_upgrade.md` |
| Entender hitbox/hurtbox | `05_game_design/combat_shapes_hitboxes_hurtboxes.md` |
| Localizar scripts | `06_reference/file_responsibilities.md` |
| Fazer testes | `08_testing/regression_module_1.md` |
| Usar ferramentas tecnicas | `07_debug_audit/README_DEBUG_AUDIT.md` |

## Termos removidos do estado atual

- `LocalizationManager`
- `pt_br.json`
- `is_gameplay_blocked`
- `RunQuery.is_run_paused`
- `hit_radius`
- `attack_hitbox_radius`
- `weapon_hitbox_radius_flat`
- `contact_damage_radius`
- dano manual por distancia para o combate atual

## ADRs recentes relevantes

- `04_decisions/adr_0011_object_pooling_para_entidades.md`
- `04_decisions/adr_0012_pausa_de_gameplay_nativa.md`
- `04_decisions/adr_0013_localizacao_nativa_godot.md`
- `04_decisions/adr_0014_input_map_nativo.md`
- `04_decisions/adr_0015_colisao_one_way_player_inimigo.md`
