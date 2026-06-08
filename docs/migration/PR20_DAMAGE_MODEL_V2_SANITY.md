# PR20 - Damage Model V2 Sanity

## Objetivo

Fechar as pendencias finais de sanidade encontradas no pacote de auditoria e alinhar o dano da Gaia com a regra oficial nova:

- `base_damage` e sempre o dano principal;
- `damage_components` nao substituem o dano principal;
- componentes fisico/magico viram bonus condicionais;
- bonus condicional so entra quando o inimigo e fraco ao tipo correspondente.

## Regra antiga

Antes desta PR, o fluxo efetivo era:

1. se o ataque tinha `damage_components`, o `DamageResolver` usava apenas os componentes;
2. `base_damage` virava fallback para armas sem componentes;
3. fraqueza e resistencia participavam do calculo principal dos componentes;
4. upgrade geral de dano podia aumentar todos os componentes em vez do dano base.

Na pratica, a arma inicial da Gaia funcionava como "dano composto principal", e nao como "dano base + bonus condicional".

## Regra nova

Agora o calculo contra inimigos fica assim:

1. `base_damage` sempre aplica;
2. cada componente e avaliado separadamente;
3. se o alvo e fraco ao tipo do componente, esse componente soma dano adicional;
4. se o alvo e resistente ao tipo, esse componente nao soma dano;
5. se o alvo e neutro ao tipo, esse componente nao soma dano;
6. resistencia e fraqueza nao alteram o `base_damage`.

## Exemplos de calculo

Configuracao da Gaia nesta PR:

- `base_damage = 6`
- `physical component = 3`
- `magical component = 3`

Resultados esperados:

| Caso | Base | Fisico | Magico | Total |
| --- | ---: | ---: | ---: | ---: |
| Inimigo neutro | 6 | 0 | 0 | 6 |
| Fraco a physical | 6 | 3 | 0 | 9 |
| Fraco a magical | 6 | 0 | 3 | 9 |
| Fraco a physical e magical | 6 | 3 | 3 | 12 |
| Resistente a physical e neutro a magical | 6 | 0 | 0 | 6 |

## Arquivos alterados

- `gameplay/combat/DamagePayload.gd`
- `gameplay/combat/DamageResolver.gd`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `gameplay/enemies/EnemyBase.gd`
- `definitions/WeaponDefinition.gd`
- `data/weapons/weapon_gaia_initial.tres`
- `gameplay/player/PlayerGaia.tscn`
- `ui/level_up/LevelUpPanel.gd`
- `project.godot`

## O que mudou tecnicamente

### DamageResolver

- passa a sempre registrar e aplicar uma entrada de breakdown `base`;
- passa a tratar cada `DamageComponentDefinition` como `conditional`;
- componentes agora informam:
  - `component_role`;
  - `applied`;
  - `reason` (`base`, `weakness`, `resistant`, `neutral`).

### DamagePayload

- `get_total_raw_damage()` agora soma `raw_damage` + componentes validos;
- o payload continua transportando:
  - `raw_damage`;
  - `damage_type`;
  - `damage_components`.

### GaiaInitialWeaponController

- upgrade geral de dano agora aumenta `base_damage`;
- upgrades especificos fisico/magico continuam aumentando apenas seus componentes;
- total bruto de debug/log agora reflete base + componentes.

### EnemyBase

- o breakdown tecnico de dano ficou mais explicito para auditoria e debugging;
- cada linha agora mostra papel do trecho, aplicacao e motivo.

## Resources alterados

### `data/weapons/weapon_gaia_initial.tres`

- passou a declarar `base_damage = 6` explicitamente;
- manteve os componentes fisico e magico como bonus condicionais;
- nao houve mudanca de attack area, spawn ou flow da run.

## Pendencias de sanidade corrigidas

### 1. Referencia antiga de attack area no `PlayerGaia.tscn`

Foi removida a referencia stale para:

- `res://resources/combat/attack_areas/attack_area_gaia_initial_d.tres`

O runtime oficial ja usa `weapon_definition` para preencher as areas ofensivas da Gaia. A referencia antiga no `.tscn` so mantinha dependencia quebrada/desnecessaria.

### 2. Fallback de icone do level-up

`LevelUpPanel.gd` apontava para um arquivo inexistente:

- `res://assets/placeholders/upgrades/upgrade_default.png`

O fallback agora usa um placeholder real existente:

- `res://assets/placeholders/upgrades/upgrade_damage.png`

### 3. Nome do projeto

`project.godot` foi alinhado para:

- `Queen Survivors`

## O que nao mudou

- RunScene;
- TestGaiaScene como cena tecnica legada;
- spawn e waves;
- moeda/magnetismo;
- save/reward/result;
- flow de XP/level-up;
- dash/movimento;
- pooling;
- debug/dev-only.

## Testes manuais

1. Abrir o projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar pelo Play principal.
4. Confirmar RunScene.
5. Atacar Goblin e validar dano base sempre aplicado.
6. Validar que Goblin ainda recebe dano e morre.
7. Validar inimigo neutro: somente `base_damage`.
8. Validar inimigo fraco: `base_damage` + componente aplicavel.
9. Validar inimigo resistente: `base_damage` preservado e componente ignorado.
10. Subir level e validar upgrade geral de dano aumentando `base_damage`.
11. Validar upgrade fisico/magico alterando apenas o bonus condicional correspondente.
12. Abrir level-up e confirmar que nenhum icone fica quebrado por fallback ausente.
13. Confirmar dash, moeda, XP, level-up, vitoria/derrota/result/save.
14. Confirmar console sem erro novo.

## Riscos conhecidos

- O Goblin atual continua configurado como fraco a physical e magical, entao a Gaia inicial segue causando o total completo nesse inimigo especifico.
- A validacao de inimigo neutro/resistente depende de teste manual com resource temporario de QA ou de um inimigo configurado para esse caso.
