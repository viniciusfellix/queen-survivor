# ADR 0014 — Input Map Nativo

## Status

Aceita.

## Problema

As actions de input eram **criadas por código** em runtime. Isso escondia o mapeamento do editor, dificultava ajuste por designer e duplicava o que o Input Map nativo do Godot já resolve.

## Decisão

Declarar todas as actions no `project.godot [input]` e deixar o código apenas **ler** o input:

- actions: `move_left`, `move_right`, `move_up`, `move_down`, `dash`, `aim_left`, `aim_right`, `aim_up`, `aim_down`;
- mover: WASD + setas + analógico esquerdo;
- mirar: analógico direito;
- dash: Espaço.

O `InputManager` apenas consulta as actions (`Input.get_axis` / `is_action_pressed`); não cria mais nenhuma action por código.

## Benefícios

- mapeamento visível e editável no editor;
- designer ajusta teclas/eixos sem tocar em código;
- alinha com o fluxo padrão do Godot.

## Conceitos removidos

Não recriar criação de actions por código. As actions vivem no Input Map do projeto; o código só as lê.
