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

## Pausa

A pausa usa o sistema nativo do Godot: `RunController` define `get_tree().paused` no level-up e no fim da run. A UI relevante roda com `process_mode = ALWAYS`; as entidades pausáveis param sozinhas. Não há mais checagem `RunQuery.is_gameplay_blocked` por frame nas entidades.

## Encerramento intermediário

`RunState.is_ending` bloqueia efeitos imediatamente quando a derrota é agendada, permitindo atraso/animação antes do painel final. Durante esse estado, dano, XP, moedas e abates adicionais não são aceitos.

No atraso de derrota (0.75s) o mundo continua rodando normalmente; a árvore só é pausada quando o `ResultPanel` abre.

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
