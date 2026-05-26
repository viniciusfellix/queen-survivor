# Lifecycle — Run

## Início

1. `RunController` carrega `MapDefinition`.
2. O mapa informa duração, vitória, timeline e pool.
3. `RunState` representa a sessão atual.
4. A cena instancia Gaia e configura o spawner.
5. HUD e painéis reagem a eventos.

## Gameplay

```text
InputManager → PlayerController → GaiaInitialWeaponController
EnemySpawner → EnemyBase → EnemyAttackHitbox
Hitboxes/Hurtboxes → DamagePayload → DamageResolver
enemy_died → XP e possível CoinDrop
XP suficiente → LevelUpPanel → aplicação de Upgrade
```

## Encerramento intermediário

`RunState.is_ending` bloqueia efeitos imediatamente quando a derrota é agendada, permitindo atraso/animação antes do painel final. Durante esse estado, dano, XP, moedas e abates adicionais não são aceitos.

## Vitória e derrota

```text
Vitória: (run_coins_collected × victory_multiplier) + victory_bonus
Derrota: run_coins_collected
```

## Persistência

```text
RunController cria RunResultPayload
→ GameEvents.run_finished
→ SaveManager.apply_run_result
→ save_to_disk
→ run_result_persisted
→ ResultPanel confirma status
```
