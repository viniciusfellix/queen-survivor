# Arquitetura — Collision Layers, Hitboxes e Hurtboxes

## Decisão

O combate foi migrado para áreas físicas reais porque a hitbox circular da primeira versão não representava a meia elipse visual da arma da Gaia e não escalaria para novos inimigos/ataques.

## Responsabilidades separadas

| Elemento | Godot | Responsabilidade |
|---|---|---|
| `BodyCollision` | `CollisionShape2D` sob `CharacterBody2D` | física e bloqueio |
| Hitbox | `Area2D` | detectar hurtbox e causar dano |
| Hurtbox | `Area2D` | representar região vulnerável e encaminhar dano |

Nunca reutilize `BodyCollision` para decidir dano.

## Layers oficiais

| Layer | Nome | Uso |
|---:|---|---|
| 1 | World | ambiente/obstáculos |
| 2 | PlayerBody | corpo físico da Gaia |
| 3 | EnemyBody | corpos físicos inimigos |
| 4 | PlayerAttackHitbox | ataques da Gaia |
| 5 | EnemyHurtbox | vulnerabilidade inimiga |
| 6 | EnemyAttackHitbox | ataques inimigos |
| 7 | PlayerHurtbox | vulnerabilidade da Gaia |
| 8 | DropPickup | drops/coleta |

```text
PlayerAttackHitbox: layer 4, mask 5
EnemyHurtbox: layer 5
EnemyAttackHitbox: layer 6, mask 7
PlayerHurtbox: layer 7
```

## Colisão de corpo one-way (Gaia ↔ inimigos)

A Gaia **não** colide com `EnemyBody` (o corpo dos inimigos). Em aglomerados a depenetração da física a ejetava, causando empurrão/teleporte; remover essa colisão eliminou o bug.

- `PlayerController._configure_enemy_body_collision()` remove o bit `EnemyBody` da `collision_mask` da Gaia no `_ready` (export `collide_with_enemy_bodies`, default `false`).
- Resultado prático: a máscara do corpo da Gaia passa a ser só `World` (não mais `World + EnemyBody`).
- Os inimigos **continuam** colidindo com a Gaia e escorregando ao redor dela (`player_body_slide`).

## Geometria configurável

`CombatShapeDefinition` armazena ID, enabled, shape, offset e rotação, e constrói a shape runtime. `AttackAreaDefinition` e `HurtboxAreaDefinition` herdam a geometria e diferenciam semanticamente ataque e vulnerabilidade.

## Shapes atuais validadas

| Fonte | Papel | Shape | Configuração |
|---|---|---|---|
| Gaia weapon | ataque | Rectangle | size `(90,300)`, local offset `(0,0)`, origin offset `160` |
| Goblin | hurtbox | Capsule | radius `21`, height `80`, offset `(0,0)` |
| Goblin | ataque | Capsule | radius `25`, height `88`, offset `(0,2)` |
| Gaia | hurtbox | Capsule | radius `23`, height `102`, offset `(0,41)` |

## Validação

Use `Debug > Visible Collision Shapes`. Ajuste tamanho na shape; use offset apenas para alinhamento. Não compense uma shape pequena deslocando-a para fora do corpo.
