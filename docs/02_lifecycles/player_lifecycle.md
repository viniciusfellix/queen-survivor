# Lifecycle — Gaia / Player

## Criação

```text
TestGaiaScene._spawn_player()
→ PlayerController lê QueenDefinition
→ PlayerRuntimeState recebe HP e velocidade
→ PlayerHurtbox é configurada pelas hurtbox_areas de queen_gaia.tres
→ GaiaVisual inicia idle
```

## Movimento e mira

Movimento controla posição e facing visual horizontal. Mira controla ataque direcional e pode vir do mouse ou analógico; não existe auto-target do inimigo mais próximo.

## Recebendo dano

```text
EnemyAttackHitbox detecta PlayerHurtbox
→ constrói DamagePayload
→ PlayerController.receive_damage(payload)
→ DamageResolver aplica defesa
→ HP é reduzido
→ player_damaged
→ flash vermelho + floating text
→ invencibilidade de 0.5s
```

## Morte

Ao zerar HP, a Gaia desativa `PlayerHurtbox`, emite `player_died`, aplica estado visual morto e faz o `RunController` iniciar derrota. Depois disso não deve receber dano adicional.
