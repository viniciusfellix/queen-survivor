# Domínio — Localização

A localização usa o sistema **nativo** do Godot: `res://data/localization/translation.csv` (recurso Translation), registrado em `project.godot [internationalization]` via `locale/translations`, com `locale/fallback="pt_BR"`. Novos textos de gameplay/UI devem possuir chave no CSV.

Os textos são resolvidos com `tr(key)`. O locale inicial é definido no boot por `App.gd` (`TranslationServer.set_locale("pt_BR")`); a troca de idioma é feita via `TranslationServer.set_locale(...)`.

Idiomas suportados (7): `pt_BR`, `en`, `es`, `zh`, `ja`, `ko`, `ru`.
