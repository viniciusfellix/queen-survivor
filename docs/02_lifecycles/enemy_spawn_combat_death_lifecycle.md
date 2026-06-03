### Ciclo de movimento e impacto do Goblin

Durante cada frame físico:

1. o Goblin verifica bloqueios da run;
2. atualiza velocidades externas de esbarrão e knockback;
3. calcula perseguição direta à Gaia;
4. reduz a perseguição se estiver sob knockback;
5. soma impulsos externos;
6. executa `move_and_slide()`;
7. processa colisões corporais com outros inimigos;
8. atualiza o visual usando a direção de perseguição.

O dano não é aplicado por colisão corporal. O ataque do Goblin permanece em `EnemyAttackHitbox`.
