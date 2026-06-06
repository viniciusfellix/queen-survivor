# ADR 0015 — Colisão One-Way Player↔Inimigo

## Status

Aceita.

## Problema

Em aglomerados de inimigos, a Gaia era empurrada e teleportada pelo centro do bando. O efeito vinha da **depenetração física**: como a Gaia colidia com cada `EnemyBody`, vários corpos sobrepostos resolviam a sobreposição empurrando a jogadora, contradizendo a intenção original do `player_body_slide`.

## Decisão

Tornar a colisão **one-way**:

- a Gaia **não colide** mais com `EnemyBody` (não é empurrada);
- os inimigos **continuam** colidindo com a Gaia e escorregando ao redor (`player_body_slide`).

Implementado em `PlayerController._configure_enemy_body_collision()`, com o export `collide_with_enemy_bodies` (default `false`).

## Benefícios

- elimina empurrão/teleporte da Gaia em hordas;
- preserva a sensação de bando: inimigos escorregam ao redor da jogadora;
- alinha com a intenção original do `player_body_slide`.

## Conceitos removidos

Não restaurar a colisão bidirecional entre a Gaia e `EnemyBody` no caminho de gameplay padrão. A jogadora ignora os corpos inimigos; o deslizamento é responsabilidade dos inimigos.
