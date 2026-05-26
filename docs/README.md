# Queen Survivors — Documentação Técnica do Módulo 1

**Estado documentado:** Módulo 1 — Core, Gaia e Arena Infinita, após a auditoria/refatoração 2R1-D e a migração validada do combate modular Hitbox/Hurtbox.  
**Engine:** Godot 4.6.1 com Spine.  
**Plataforma inicial:** PC.  
**Cena técnica atual:** `res://gameplay/test/TestGaiaScene.tscn`.

## Objetivo desta pasta

Esta documentação é a referência técnica do protótipo funcional atual. Ela explica a arquitetura, os fluxos de run, as regras de game design configuráveis por resources, as ferramentas de debug/audit e os testes que precisam continuar passando após novas implementações.

## Ordem de leitura recomendada

1. [`00_project/module_1_status.md`](00_project/module_1_status.md) — escopo implementado e pendências.
2. [`00_project/glossary.md`](00_project/glossary.md) — termos oficiais.
3. [`01_architecture/scene_architecture.md`](01_architecture/scene_architecture.md) — estrutura runtime.
4. [`01_architecture/collision_layers_and_combat_shapes.md`](01_architecture/collision_layers_and_combat_shapes.md) — base do combate atual.
5. [`02_lifecycles/run_lifecycle.md`](02_lifecycles/run_lifecycle.md) — fluxo de uma partida.
6. [`03_domains/combat_damage/damage_domain.md`](03_domains/combat_damage/damage_domain.md) — dano e hitboxes.
7. [`05_game_design/README_GAME_DESIGN.md`](05_game_design/README_GAME_DESIGN.md) — edição segura de balanceamento.
8. [`06_reference/file_responsibilities.md`](06_reference/file_responsibilities.md) — localizar rapidamente um arquivo.
9. [`07_debug_audit/README_DEBUG_AUDIT.md`](07_debug_audit/README_DEBUG_AUDIT.md) — ferramentas técnicas.
10. [`08_testing/regression_module_1.md`](08_testing/regression_module_1.md) — regressão obrigatória.

## Regras oficiais atuais

- O projeto se chama **Queen Survivors**.
- O protótipo começa com a Queen **Gaia**.
- O primeiro mapa é infinito e possui duração oficial de **10 minutos**.
- XP é única: entra diretamente na barra de level-up da run e compõe o progresso persistido ao final.
- Moeda é drop físico; só conta quando coletada e é perdida quando deixada no mapa.
- Vitória: `dinheiro_final = (moedas_coletadas × victory_multiplier) + victory_bonus`.
- Derrota: `dinheiro_final = moedas_coletadas`.
- A arma inicial da Gaia aponta pela mira do mouse ou analógico, não pelo inimigo mais próximo.
- A arma da Gaia possui dano híbrido físico e mágico.
- O Goblin atual é fraco a dano físico e mágico, com bônus de fraqueza de 50%.
- Textos visíveis devem nascer preparados para localização.
- Antes de encerrar qualquer módulo: auditar, limpar, comentar, testar e documentar.

## Combate modular oficial

O antigo dano por raio/círculo e o dano de contato calculado por distância foram substituídos por áreas físicas configuráveis em resources:

```text
GaiaInitialWeaponController
→ DirectionalAttackHitbox <Area2D>
→ EnemyBase/Hurtbox <Area2D>
→ EnemyBase.receive_damage()
→ DamageResolver
→ flash claro / morte / recompensa
```

```text
EnemyBase/ContactAttackHitbox <Area2D>
→ PlayerGaia/PlayerHurtbox <Area2D>
→ PlayerController.receive_damage()
→ DamageResolver
→ flash vermelho / texto flutuante / invencibilidade / derrota
```

## Navegação rápida

| Necessidade | Documento |
|---|---|
| Alterar a arma da Gaia | `05_game_design/edit_gaia_weapon.md` |
| Alterar o Goblin | `05_game_design/edit_goblin.md` |
| Criar inimigo | `05_game_design/create_new_enemy.md` |
| Criar ataque ou arma | `05_game_design/create_new_weapon_or_attack.md` |
| Criar upgrade | `05_game_design/create_new_upgrade.md` |
| Entender Hitbox/Hurtbox | `05_game_design/combat_shapes_hitboxes_hurtboxes.md` |
| Localizar scripts | `06_reference/file_responsibilities.md` |
| Fazer testes | `08_testing/regression_module_1.md` |
| Usar audit/debug | `07_debug_audit/README_DEBUG_AUDIT.md` |

## Termos removidos

Documentação ou código novo não deve voltar a usar `hit_radius`, `attack_hitbox_radius`, `weapon_hitbox_radius_flat`, `contact_damage_radius`, dano manual por distância ou `contains_local_point` para resolver impactos atuais.
