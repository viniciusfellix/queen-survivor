# Runtime Tree Snapshot

`RuntimeTreeSnapshot` exporta nodes reais da execução, grupos e scripts anexados. O sistema compacta subárvores Spine para evitar centenas de `SpineMesh2D` no console.

## Usar quando

- um node não é localizado;
- houver suspeita de duplicidade;
- cenas foram alteradas;
- uma hitbox/hurtbox parece ser criada duas vezes;
- antes do fechamento de módulo.

## Revisão atual esperada

- Gaia possui `PlayerHurtbox`.
- Goblin possui `Hurtbox` e `ContactAttackHitbox`.
- Shapes runtime existem somente conforme definitions configuradas.
- Não existe definition específica duplicada em `EnemyBase.tscn`.
