# Lifecycle — Player Gaia

## Criação

```txt
TestGaiaScene instancia PlayerGaia
↓
PlayerController cria PlayerRuntimeState
↓
QueenDefinition aplica HP e velocidade base
↓
GaiaVisual é encontrado
↓
GaiaInitialWeaponController é iniciado
```

## Input

```txt
InputManager.update_input_for_player()
↓
move_direction
aim_direction
↓
PlayerRuntimeState.apply_input()
```

## Movimento visual

```txt
move_direction horizontal
↓
facing_direction
↓
GaiaVisualController aplica scale.x
```

## Mira

```txt
Mouse
↓
aim_direction
↓
Linha amarela
↓
GaiaInitialWeaponController usa para ataque
```

A mira não controla o lado visual do corpo.

## Dano recebido

```txt
EnemyBase cria DamagePayload
↓
PlayerController.receive_damage()
↓
DamageResolver.calculate_received_damage()
↓
PlayerRuntimeState.apply_damage()
```

## Morte

```txt
HP <= 0
↓
PlayerRuntimeState.kill()
↓
state = dead
↓
GaiaVisualController toca Die_Pose1
```
