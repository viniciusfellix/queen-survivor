# Dominio - Localizacao

A localizacao usa o sistema nativo do Godot:

- arquivo fonte versionado: `res://data/localization/translation.csv`
- registro no projeto: `project.godot [internationalization]`
- fallback atual: `locale/fallback="pt_BR"`
- resolucao de texto: `tr(key)`

O locale inicial e definido no boot por `App.gd` via `TranslationServer.set_locale("pt_BR")`.

## Estado atual

- Nao existe mais `LocalizationManager` em runtime.
- Nao existe mais JSON proprio como source of truth de traducao.
- O CSV nativo da Godot e a fonte atual de traducao versionada.

## Idiomas suportados

`pt_BR`, `en`, `es`, `zh`, `ja`, `ko`, `ru`

## Regras para novos textos

- criar a chave em `translation.csv`
- usar `tr("chave")` no codigo ou em scripts de UI
- nao criar sistema paralelo de lookup textual
