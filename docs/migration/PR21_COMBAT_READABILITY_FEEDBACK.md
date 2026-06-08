# PR21 - Combat Readability Feedback

## Objetivo

Melhorar a leitura visual do combate da Gaia sem alterar:

- regra de dano da PR20;
- hitbox real;
- cooldown;
- knockback;
- spawn/waves;
- save/reward/result.

A PR atua em dois pontos:

1. indicador visual de mira/alcance da arma direcional;
2. sequencia visual de feedback de dano para Gaia e inimigos.

## Como o indicador visual funciona

Foi criada a cena:

- `res://visual/weapons/gaia_initial_weapon/GaiaAimIndicator.tscn`

com o script:

- `res://visual/weapons/gaia_initial_weapon/GaiaAimIndicator.gd`

O indicador:

- e um `Node2D` com `Sprite2D`;
- nao tem colisao;
- nao causa dano;
- nao interage com `DirectionalAttackHitbox`;
- nao altera attack area, alcance real ou cooldown;
- so acompanha a direcao de mira atual.

Ele fica como child visual da Gaia em:

- `gameplay/player/PlayerGaia.tscn`
- `VisualRoot/GaiaAimIndicator`

O `GaiaVisualController` atualiza a orientacao do indicador usando `aim_direction` ou `last_valid_aim_direction`, e o `PlayerController` faz a configuracao inicial do raio usando os dados da arma ativa.

## Como a distancia visual foi definida

A prioridade ficou assim:

1. se `GaiaInitialWeaponController.aim_indicator_radius_pixels` estiver preenchido, ele e usado como override explicito;
2. caso contrario, a arma calcula um alcance frontal aproximado a partir da configuracao real:
   - `attack_hitbox_offset`;
   - shape runtime de `attack_areas`;
   - `local_offset` da area;
   - ponto frontal maximo da shape.

Para a Gaia atual, isso resulta em aproximacao baseada em:

- `attack_hitbox_offset = 160`
- attack area convexa com alcance frontal efetivo de aproximadamente `96`

Total visual aproximado:

- `256 px`

Esse valor continua sendo apenas indicador visual de frente/alcance, nao contrato de colisao.

## Asset do indicador

O placeholder adicionado pelo usuario tinha typo no nome:

- antigo: `gaia_drectional_attack.png`
- novo: `gaia_directional_attack.png`

Tambem foi alinhado o arquivo:

- `gaia_directional_attack.png.import`

As referencias finais desta PR usam o nome corrigido.

## Hooks de sensibilidade

Foram adicionados exports simples no `PlayerController`:

- `mouse_aim_sensitivity`
- `analog_aim_sensitivity`

Estado atual:

- servem como hooks seguros para menu futuro;
- defaults ficam em `1.0`;
- nao alteram o feel atual;
- nao foram ligados ao `InputManager` nesta PR porque a mira atual e normalizada em vetor de direcao, entao multiplicar "sensibilidade" localmente sem refatorar a captura de input seria cosmetico e potencialmente enganoso.

Pendencia futura:

- mover sensibilidade real para o dominio do `InputManager` ou para um filtro de aim com smoothing/response curve configuravel.

## Sequencia de feedback visual

### Gaia

O flash simples foi substituido por sequencia configuravel em:

- `visual/characters/gaia/GaiaVisualController.gd`

Sequencia default:

- vermelho -> preto -> vermelho -> normal

Configuracao:

- `damage_flash_colors`
- `damage_flash_step_seconds`
- `restore_default_between_flash_colors`

### Enemy

O flash simples do Goblin foi substituido por sequencia configuravel em:

- `visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`

Sequencia default:

- branco -> normal -> branco -> normal

A implementacao usa:

- `damage_flash_colors = [white, white]`
- `restore_default_between_flash_colors = true`

## Seguranca de reuso / tween

Nos dois visual controllers:

- tween antigo e morto antes de iniciar novo feedback;
- `modulate` volta para `default_modulate` ao finalizar;
- inimigo pooled continua resetando flash/tween no `reset_visual_state()` e `deactivate_for_pool()`;
- o indicador de mira nao usa pooling nem estado de combate.

## O que foi removido/substituido da logica antiga

### Substituido

- flash unico de cor na Gaia;
- flash unico com brilho branco no Goblin.

### Mantido

- blink overlay;
- Spine adapters;
- runtime visual idle/run/dash/death;
- pooling/reset do Goblin;
- fluxo de dano e combate.

## Arquivos alterados

- `gameplay/player/PlayerController.gd`
- `gameplay/player/PlayerGaia.tscn`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `visual/characters/gaia/GaiaVisualController.gd`
- `visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`
- `assets/placeholders/weapons/gaia_initial_weapon/gaia_directional_attack.png`
- `assets/placeholders/weapons/gaia_initial_weapon/gaia_directional_attack.png.import`

## Arquivos criados

- `visual/weapons/gaia_initial_weapon/GaiaAimIndicator.gd`
- `visual/weapons/gaia_initial_weapon/GaiaAimIndicator.tscn`

## O que nao mudou

- `DamageResolver`
- `DamagePayload`
- regra de dano da PR20
- base_damage e componentes
- cooldown da arma
- attack area real
- hitbox real
- knockback
- spawn/waves
- moedas
- XP/level-up
- save/reward/result

## Testes manuais

1. Abrir o projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar pelo Play principal.
4. Confirmar `RunScene`.
5. Mover a Gaia.
6. Mirar com mouse.
7. Confirmar que o indicador gira corretamente.
8. Confirmar que o indicador fica ao redor da Gaia no limite visual do ataque.
9. Atacar e confirmar que hitbox/dano real nao mudou.
10. Confirmar Goblin recebe dano e morre.
11. Confirmar que a regra da PR20 continua igual.
12. Tomar dano na Gaia e confirmar vermelho -> preto -> vermelho -> normal.
13. Dar dano no enemy e confirmar branco -> normal -> branco -> normal.
14. Matar e reutilizar Goblins e confirmar ausencia de cor suja.
15. Confirmar dash.
16. Confirmar moeda.
17. Confirmar XP/level-up.
18. Confirmar vitoria/derrota/result/save.
19. Confirmar console sem erro novo.

## Riscos e pendencias futuras

- A aproximacao visual do alcance frontal funciona para a attack area atual, mas ainda e uma leitura visual, nao geometria exata da shape "D".
- Os hooks de sensibilidade estao expostos, mas a aplicacao real continua pendente de revisao do `InputManager`.
- O indicador usa um placeholder novo; pode precisar de ajuste fino de `position_offset`, `indicator_scale` ou `angle_offset_degrees` depois de abrir no editor e ver o framing real do sprite.
