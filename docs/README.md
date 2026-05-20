# Queen Survivors — Documentação do Módulo 1

Esta pasta documenta a arquitetura atual do **Queen Survivors — Módulo 1: Core, Gaia e Arena Infinita**.

A documentação foi separada em duas frentes:

1. **Documentação técnica**  
   Para programadores, engenheiros de gameplay e pessoas que vão mexer em scenes, scripts, runtime, eventos e arquitetura.

2. **Game Design / Balanceamento**  
   Para game designers, artistas técnicos e pessoas que precisam editar dano, XP, moedas, fraquezas, cooldowns, placeholders e assets sem entender todo o código.

## Ordem recomendada de leitura

Para desenvolvedores:

1. `00_project/module_1_status.md`
2. `01_architecture/folder_structure.md`
3. `01_architecture/scene_architecture.md`
4. `01_architecture/event_bus.md`
5. `02_lifecycles/run_lifecycle.md`
6. `03_domains/`

Para game designers:

1. `05_game_design/README_GAME_DESIGN.md`
2. `05_game_design/where_to_edit_balance.md`
3. `05_game_design/edit_goblin.md`
4. `05_game_design/edit_gaia_weapon.md`
5. `05_game_design/create_new_enemy.md`
6. `05_game_design/create_new_weapon_or_attack.md`

## Estado atual do módulo

O projeto já possui:

- Gaia com Spine funcionando.
- Movimento por WASD/setas.
- Mira separada por mouse.
- Facing visual baseado no movimento horizontal.
- Arena de teste com grid.
- FollowCamera.
- Goblin Warrior com Spine.
- Spawner de inimigos.
- Dano de contato do inimigo contra Gaia.
- HP, defesa, dano mínimo e morte da Gaia.
- Arma inicial da Gaia com ataque direcional.
- Visual placeholder do ataque por PNG.
- Hitbox direcional.
- Dano híbrido físico + mágico por componentes.
- Fraquezas e resistências do inimigo.
- XP direta por morte.
- Level-up com 3 opções.
- Moeda física com magnetismo e coleta.
