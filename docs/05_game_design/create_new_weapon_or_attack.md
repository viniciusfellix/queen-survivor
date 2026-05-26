# Criar Nova Arma ou Ataque de Queen

1. Crie `WeaponDefinition` com ID, localization, cooldown, visual, lifetime e área ofensiva.
2. Para dano composto, crie resources `DamageComponentDefinition` separados.
3. Crie `AttackAreaDefinition` alinhada ao visual.
4. Reutilize `DirectionalAttackHitbox` para ataques direcionais instantâneos compatíveis.
5. Ataques persistentes/projéteis/summons podem exigir controller próprio, sempre enviando `DamagePayload` a hurtboxes.
6. Teste shape, centro/bordas, dano, upgrades e morte do alvo.

Tipos atuais de dano: `physical`, `magical`, `fire`, `ice`, `lightning`, `poison`, `true_damage`.
