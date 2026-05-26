# Arquitetura — Resources e Runtime

## Resources

Dados editáveis pelo game designer devem permanecer em `.tres`: Queen, inimigo, arma, ataque, shape, upgrade, mapa, wave e drop.

## Runtime

Runtime armazena valores temporários: HP, posições, XP, moedas, stacks, cooldowns, shapes instanciadas e resultado em construção. Ele não deve editar resources originais diretamente; components que recebem modificação em run devem duplicar definitions quando necessário.

## Definitions centrais

| Definition | Responsabilidade |
|---|---|
| `QueenDefinition` | atributos, arma inicial, visual e hurtboxes da Queen |
| `EnemyDefinition` | atributos, ataque, fraquezas, recompensas e hurtboxes |
| `WeaponDefinition` | cooldown, visual, components e attack areas |
| `CombatShapeDefinition` | geometria compartilhada configurável |
| `AttackAreaDefinition` | shape ofensiva |
| `HurtboxAreaDefinition` | shape vulnerável |
| `EnemyAttackDefinition` | dano, timing e shapes do ataque inimigo |
| `UpgradeDefinition` | uma opção de level-up |
| `UpgradePoolDefinition` | opções disponíveis e regras de repetição |
| `MapDefinition` | duração, recompensa, spawn e pool |
| `SpawnTimelineDefinition` | waves por faixa temporal |
| `CoinDropDefinition` | moeda/magnetismo/coleta |

## Fonte única

Uma cena genérica executa comportamento; o resource define o conteúdo. `EnemyBase.tscn` não deve reter uma `EnemyDefinition` específica ou attack definition duplicada; o Goblin recebe `enemy_chaser_basic.tres` pelo spawn.
