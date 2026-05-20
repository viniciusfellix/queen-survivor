# Onboarding para Desenvolvedores

## Primeiro entendimento

O projeto usa uma separação rígida entre:

- Dados configuráveis.
- Runtime de gameplay.
- Visual.
- UI.
- Eventos.
- Save.

Essa separação evita que animação controle regra de jogo ou que assets visuais virem dependência da lógica.

## Regra mais importante

A gameplay não depende diretamente do Spine.

Fluxo correto:

```txt
Gameplay State
→ Visual Controller
→ Spine Adapter
→ SpineSprite
```

Nunca:

```txt
SpineSprite
→ decide dano, morte, cooldown ou movimento
```

## Onde começar a ler

1. `01_architecture/folder_structure.md`
2. `01_architecture/scene_architecture.md`
3. `01_architecture/event_bus.md`
4. `02_lifecycles/run_lifecycle.md`
5. `03_domains/player/player_domain.md`
6. `03_domains/weapons/weapon_domain.md`

## Como testar o projeto atualmente

1. Abrir a cena principal configurada em `Main.tscn`.
2. Conferir se `Main.gd` carrega `TestGaiaScene.tscn`.
3. Rodar o jogo.
4. Mover Gaia com WASD.
5. Mirar com mouse.
6. Observar goblins spawnando.
7. Matar goblins com ataque automático.
8. Ver XP, level-up e moedas no debug overlay.

## Convenções atuais

- Dados ficam em `res://data/`.
- Definitions ficam em `res://definitions/`.
- Lógica runtime fica em `res://gameplay/`.
- Estados runtime ficam em `res://runtime/`.
- Visual fica em `res://visual/`.
- Assets brutos ficam em `res://assets/`.
- UI fica em `res://ui/`.
- Constantes ficam em `res://core/constants/`.
