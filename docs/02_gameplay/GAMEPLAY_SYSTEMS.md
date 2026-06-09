# Gameplay Systems

## Gaia

- movimento via `CharacterBody2D`
- mira por mouse/analogico
- dash com janela de invulnerabilidade configuravel
- ataque direcional sem auto-aim

## Ataque inicial

- `GaiaInitialWeaponController`
- `DirectionalAttackHitbox`
- feedback visual separado do dano real
- aim indicator puramente visual

## XP e level-up

- XP entra direto, sem drop fisico
- `RunState` acumula XP
- `LevelUpPanel` oferece opcoes validas

## Moedas

- moeda fisica pooled
- idle inicial
- magnetismo por `Area2D`
- coleta por `Area2D`
- apenas moedas coletadas entram em resultado

## Resultado e save

- vitoria/derrota resolvidas por `RunController`
- `RewardResolver` calcula recompensa final
- `SaveManager` persiste estado relevante
