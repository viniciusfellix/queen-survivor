# Lifecycle — Inimigo

## Spawn

```txt
EnemySpawner
↓
load EnemyBase.tscn
↓
EnemyRoot.add_child
↓
EnemyBase.setup(enemy_definition, player)
```

## Inicialização

```txt
EnemyBase._ready()
↓
add_to_group("enemy")
↓
aplica EnemyDefinition
↓
encontra target
↓
encontra visual controller
```

## Movimento

```txt
EnemyBase._physics_process
↓
_follow_target()
↓
move_and_slide()
↓
_update_visual_state()
```

## Dano no player

```txt
distância até player <= contact_damage_radius
↓
cooldown de contato disponível
↓
PlayerController.receive_damage()
```

## Dano recebido

```txt
DirectionalAttackHitbox detecta EnemyBase
↓
EnemyBase.receive_damage(payload)
↓
DamageResolver.calculate_enemy_damage()
↓
HP reduz
```

## Morte

```txt
HP <= 0
↓
EnemyBase.die()
↓
GameEvents.enemy_died
↓
RunController adiciona XP
↓
DropController talvez cria moeda
↓
Goblin toca Die
↓
remove_from_group("enemy")
↓
queue_free após timer
```
