# ADR 0012 — Pausa de Gameplay Nativa

## Status

Aceita.

## Problema

A pausa de gameplay (level-up e fim de run) era resolvida por uma checagem de bloqueio consultada **a cada frame**: `RunQuery.is_gameplay_blocked` / `is_run_paused`. Essa checagem fazia `get_nodes_in_group` mais reflexão em toda entidade, com custo alto em hordas. Cada entidade pagava o preço da consulta mesmo quando nada estava pausado.

## Decisão

Usar o sistema nativo de pausa do Godot:

- o `RunController` chama `get_tree().paused` no level-up e no fim de run;
- a UI que precisa continuar respondendo usa `process_mode = ALWAYS`;
- sem nenhuma checagem de bloqueio por frame nas entidades.

No delay de derrota (`0.75s`) o mundo **continua** rodando; a pausa só ocorre no `ResultPanel`.

## Benefícios

- elimina `get_nodes_in_group` + reflexão por frame em cada entidade;
- pausa real e gratuita via engine;
- comportamento previsível: só o que tem `process_mode = ALWAYS` roda durante a pausa.

## Conceitos removidos

Não recriar `RunQuery.is_gameplay_blocked`, `is_run_paused` ou qualquer checagem de bloqueio de gameplay por frame. Pausa é feita por `get_tree().paused` + `process_mode = ALWAYS`.
