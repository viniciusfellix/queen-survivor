# Status do Módulo 1

## Nome

Queen Survivors — Módulo 1: Core, Gaia e Arena Infinita

## Objetivo do módulo

Criar a primeira base jogável real do projeto em Godot, com Gaia, arena de teste, inimigo perseguidor, ataque direcional, XP direta, level-up inicial, moeda física e magnetismo.

## Checkpoints concluídos

### QS-M1-001 — Base inicial da Gaia

Validado:

- Godot com Spine integrado.
- Gaia carregando via `SpineSprite`.
- `GaiaSpineAdapter` encontrando o `SpineSprite`.
- Animação `Idle1_Pose2`.
- Animação `Run1_Pose3`.
- Movimento.
- Mira por mouse.
- Linha de debug da mira.
- Câmera seguindo Gaia.
- `DebugOverlay`.

### QS-M1-002 — Primeiro inimigo perseguidor

Validado:

- `EnemyDefinition`.
- `enemy_chaser_basic.tres`.
- `EnemyBase.tscn`.
- `EnemySpawner.tscn`.
- Spawn em volta da Gaia.
- Inimigo perseguindo player.
- Organização em `RuntimeRoot/EnemyRoot`.

### QS-M1-003 — Dano, defesa e morte da Gaia

Validado:

- Dano de contato do goblin.
- HP da Gaia.
- Fórmula de defesa.
- Dano mínimo 1.
- Morte da Gaia.
- Animação `Die_Pose1`.

### QS-M1-004 — Goblin Warrior com Spine

Validado:

- Skeleton resource do goblin.
- `GoblinWarriorVisual.tscn`.
- `GoblinWarriorSpineAdapter`.
- `GoblinWarriorVisualController`.
- Animações `Idle`, `Run` e `Die`.

### QS-M1-005 — Ataque direcional da Gaia

Validado:

- Arma inicial da Gaia.
- Ataque automático por cooldown.
- Direção por `aim_direction`.
- Placeholder visual por PNG.
- Hitbox direcional.
- Dano no goblin.
- Morte do goblin.

### QS-M1-006 — Dano híbrido

Validado:

- Componentes `physical` e `magical`.
- `DamageComponentDefinition`.
- `DamagePayload` com componentes.
- `DamageResolver` com fraqueza/resistência.
- Goblin fraco a físico.
- Goblin fraco a mágico.
- Goblin fraco aos dois.
- Resistência mágica validada.

### QS-M1-007 — XP direta e level-up

Validado:

- XP entra diretamente ao matar inimigo.
- XP não cai no chão.
- `RunController` escuta morte de inimigo.
- `RunState` acumula XP.
- Level interno sobe.
- `LevelUpPanel` abre com 3 opções.
- Upgrades de dano, cooldown, velocidade e HP funcionam.

### QS-M1-008 — Moeda física

Validado:

- Moeda dropa no chão.
- Moeda não entra automaticamente.
- Magnetismo.
- Coleta.
- `run_coins_collected`.
- `run_coins_available`.
- XP e moeda estão separados corretamente.

### QS-M1-009 — Timer da run, vitória, derrota e resultado básico

Validado:

- `MapDefinition` criado.
- `map_test_arena_10min.tres` criado.
- Mapa configurado com duração oficial de 10 minutos.
- Duração do mapa configurável para testes.
- `RunController` carregando `MapDefinition`.
- Timer da run funcionando.
- Tempo restante exibido no debug.
- Vitória disparando ao fim do tempo do mapa.
- Derrota disparando quando Gaia morre.
- `RunResultPayload` criado.
- `RewardResolver` criado.
- Fórmula oficial de vitória validada.
- Fórmula oficial de derrota validada.
- Moeda não coletada não entra no resultado.
- XP da run aparece no resultado.
- Kills aparecem no resultado.
- Nível alcançado aparece no resultado.
- Dano causado e dano recebido aparecem no resultado.
- Causa da morte aparece em derrota.
- `ResultPanel` criado.
- `ResultPanel` exibe payload recebido, sem recalcular resultado.
- Gameplay pausa ao final da run.

Regras validadas:

```txt
Vitória:
dinheiro_final = (moedas_coletadas × victory_multiplier) + victory_bonus

Derrota:
dinheiro_final = moedas_coletadas
