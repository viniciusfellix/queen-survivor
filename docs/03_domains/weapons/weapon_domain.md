# Domínio — Armas

## Arquivos principais

```txt
definitions/WeaponDefinition.gd
definitions/DamageComponentDefinition.gd
data/weapons/weapon_gaia_initial.tres
data/weapons/components/
gameplay/weapons/gaia/GaiaInitialWeaponController.gd
gameplay/weapons/attacks/DirectionalAttackHitbox.gd
visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn
```

## WeaponDefinition

Configura:

- ID.
- Nome.
- Cooldown.
- Visual do ataque.
- Offset visual.
- Hitbox.
- Offset da hitbox.
- Raio da hitbox.
- Lifetime.
- Componentes de dano.

## GaiaInitialWeaponController

Executa a arma em runtime:

- Lê `aim_direction`.
- Controla cooldown.
- Cria visual.
- Cria hitbox.
- Aplica upgrades de dano/cooldown.

## DirectionalAttackHitbox

Responsável por:

- Detectar inimigos.
- Enviar `DamagePayload`.
- Garantir que a mesma hitbox não acerte o mesmo inimigo várias vezes.

## Visual do ataque

Atualmente:

```txt
assets/placeholders/weapons/gaia_initial_weapon/gaia_attack_placeholder.png
```

Scene:

```txt
visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn
```

Pode usar placeholder agora e Spine no futuro.
