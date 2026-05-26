# Criar Novo Inimigo

1. Crie `EnemyDefinition` (`enemy_<nome>.tres`) com ID, localization, atributos, recompensas e visual.
2. Crie uma ou mais `HurtboxAreaDefinition` em pasta apropriada e vincule a `hurtbox_areas`.
3. Crie `AttackAreaDefinition` e `EnemyAttackDefinition` para ataques necessários.
4. Vincule o ataque no campo suportado pela definition; atualmente o perseguidor usa `contact_attack`.
5. Reutilize `EnemyBase.tscn` apenas se o comportamento for compatível; não duplique regras de dano.
6. Inclua localization.
7. Inclua o inimigo em uma entrada da timeline.
8. Teste spawn, shapes, ataque, dano, morte, rewards e console.

Novas geometrias podem ser círculo, cápsula, retângulo ou outra forma suportada pelo sistema, conforme necessidade de arte/game design.
