# ADR 0013 — Localização Nativa do Godot

## Status

Aceita.

## Problema

A localização usava uma solução própria: o autoload `LocalizationManager` carregava `data/localization/pt_br.json` e os textos eram obtidos por uma função própria. Isso duplicava infraestrutura que o Godot já oferece nativamente, sem integração com o editor nem com o fluxo padrão de tradução.

## Decisão

Migrar para o sistema de tradução nativo do Godot:

- `data/localization/translation.csv` como `Translation` importada;
- `project.godot [internationalization]` declara `locale/translations` e `locale/fallback="pt_BR"`;
- textos obtidos via `tr(key)`;
- `App.gd` define o idioma inicial com `TranslationServer.set_locale("pt_BR")`.

Idiomas oficiais (7): `pt_BR`, `en`, `es`, `zh`, `ja`, `ko`, `ru`.

## Benefícios

- integração nativa com editor e runtime do Godot;
- fallback automático para `pt_BR`;
- elimina autoload e parser de JSON próprios;
- chaves de tradução centralizadas em CSV editável.

## Conceitos removidos

Não recriar `LocalizationManager`, `data/localization/pt_br.json` nem função própria de obtenção de texto. Textos visíveis usam `tr(key)` sobre o CSV nativo.
