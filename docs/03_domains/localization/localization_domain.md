# Domínio — Localização

## Arquivos

```txt
autoloads/LocalizationManager.gd
data/localization/pt_br.json
```

## Regra

Não escrever textos finais hardcoded em lógica.

Usar chaves:

```txt
queen.gaia.name
enemy.chaser_basic.name
weapon.gaia_initial.name
ui.level_up.title
```

## Idiomas planejados

- Português.
- Inglês.
- Espanhol.
- Coreano.
- Chinês.
- Japonês.

## Estado atual

Só `pt_br.json` é usado no protótipo.

## Ao criar novo conteúdo

Sempre criar:

- `display_name_key`
- `description_key`

E adicionar no JSON.
