# ADR — Movimento orgânico de perseguidores por esbarrão físico, knockback configurável e blink overlay

## Status

Aceita.

## Contexto

Durante o Módulo 1 do Queen Survivors, o inimigo perseguidor básico Goblin funcionava corretamente em combate, mas múltiplos Goblins tendiam a se acumular visualmente no centro da Gaia.

O problema prejudicava:

- leitura visual do combate;
- percepção da área real da arma da Gaia;
- sensação de bando;
- clareza da pressão inimiga;
- naturalidade da movimentação.

A arquitetura de combate modular já estava concluída e não deveria ser alterada:

```txt
BodyCollision = colisão física/movimento
Hitbox = área ofensiva
Hurtbox = área vulnerável
