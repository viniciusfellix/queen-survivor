# PR9 - Godot Native Localization

## Objetivo da PR

Consolidar a migracao para localizacao nativa da Godot 4.6 sem reintroduzir infraestrutura legada. A auditoria desta PR confirmou que o projeto ja nao usa mais `LocalizationManager` nem JSON de traducao em runtime; a base atual ja opera com `TranslationServer`, `tr(key)` e arquivos nativos importados pela engine.

## Estado encontrado

- `autoloads/LocalizationManager.gd` nao existe mais no projeto.
- `data/localization/pt_br.json` nao existe mais no projeto.
- `data/localization/translation.csv` ja e a fonte de texto versionada.
- O editor ja gerou e o projeto ja registra:
  - `translation.pt_BR.translation`
  - `translation.en.translation`
  - `translation.es.translation`
  - `translation.zh.translation`
  - `translation.ja.translation`
  - `translation.ko.translation`
  - `translation.ru.translation`
- `project.godot` ja possui `[internationalization] locale/translations`.
- `autoloads/App.gd` ja aplica `TranslationServer.set_locale("pt_BR")` no boot.
- Scripts de UI inspecionados ja usam `tr(key)` diretamente:
  - `ui/hud/RunHud.gd`
  - `ui/level_up/LevelUpPanel.gd`
  - `ui/result/ResultPanel.gd`
  - `ui/feedback/RunFeedbackLayer.gd`
  - `ui/debug/tools/PrototypeToolsPanel.gd`
  - `ui/debug/DebugOverlay.gd`

## O que esta PR faz

1. Registra formalmente que a migracao para o sistema nativo da Godot ja esta efetivamente concluida na base atual.
2. Adiciona `locale/fallback="pt_BR"` em `project.godot` para alinhar a configuracao do projeto com a documentacao e garantir fallback nativo explicito.
3. Corrige documentacao residual que ainda descrevia `data/localization/` como pasta de JSON.
4. Documenta que a source of truth atual da localizacao e o CSV nativo do projeto.

## O que esta PR nao faz

- Nao recria `LocalizationManager`.
- Nao recria JSON antigo.
- Nao altera gameplay.
- Nao altera cenas.
- Nao altera layout de UI.
- Nao muda chaves de localizacao.
- Nao implementa tela de selecao de idioma.
- Nao muda save.

## Source of truth atual

- Fonte versionada principal: `res://data/localization/translation.csv`
- Artefatos importados pela engine: `res://data/localization/*.translation`
- Resolucao em runtime: `tr(key)` / `TranslationServer`
- Locale inicial atual: `pt_BR`, aplicado por `autoloads/App.gd`

## Preservacao das chaves antigas

As chaves existentes ja foram preservadas na migracao anterior. Esta PR verificou que o CSV mantem o catalogo usado pela UI atual, incluindo chaves como:

- `game.title`
- `queen.gaia.name`
- `drop.coin.default.name`
- `enemy.chaser_basic.name`
- `ui.hud.*`
- `ui.level_up.*`
- `ui.result.*`
- `ui.feedback.*`

Como o JSON legado ja nao existe mais, esta PR nao faz conversao adicional; apenas documenta que o CSV atual e o catalogo vivo.

## Ponte temporaria

Nenhuma ponte `LocalizationManager -> TranslationServer` foi adicionada nesta PR porque ela ja nao e necessaria na base atual: o manager legado foi removido anteriormente e os scripts inspecionados ja consomem `tr(key)` diretamente.

Decisao desta PR: **nao reintroduzir wrapper legado** so para simular uma migracao que ja aconteceu.

## Arquivos alterados

- `project.godot`
- `docs/01_architecture/folder_structure.md`

## Arquivos criados

- `docs/migration/PR9_GODOT_NATIVE_LOCALIZATION.md`

## Testes manuais necessarios

1. Abrir o projeto no Godot.
2. Confirmar que nao ha missing files.
3. Confirmar que `data/localization/translation.csv` continua importado pela engine.
4. Rodar o jogo pelo botao principal/play.
5. Confirmar que a cena carregada e `RunScene`.
6. Confirmar textos principais:
   - HUD
   - level-up
   - resultado
   - feedback de moeda
   - feedback de level-up
   - ferramentas tecnicas, se habilitadas
7. Confirmar que nenhuma label aparece vazia.
8. Confirmar que chaves ausentes, se houver alguma, aparecem como key e nao quebram a UI.
9. Confirmar que Gaia move, dash funciona, ataque funciona, Goblin spawna, moeda dropa/coleta, XP/level-up funcionam, vitoria/derrota/result/save continuam funcionando.
10. Confirmar console sem erro novo.

## Riscos conhecidos

- O projeto depende do import do editor para manter os `.translation` sincronizados com o CSV. Se o CSV for alterado fora do editor, e preciso reabrir/reimportar no Godot para regenerar os artefatos importados.
- `App.gd` ainda fixa `pt_BR` no boot. Isso e aceitavel nesta fase, mas a selecao real de idioma ainda precisa vir de configuracao do jogador em PR futura.

## Proximos passos esperados

1. Persistir locale selecionado em save/configuracao.
2. Adicionar fluxo de troca de idioma na UI quando esse requisito existir.
3. Continuar proibindo expansao de sistemas legados de localizacao fora do pipeline nativo da Godot.
