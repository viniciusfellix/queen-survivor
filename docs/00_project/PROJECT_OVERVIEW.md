# Project Overview

## Projeto

`Queen Survivors` e um survivor-like 2D em `Godot 4.6.1` com integracao Spine.

## Estado atual do prototipo

- Cena oficial da run: `res://scenes/run/RunScene.tscn`
- Cena de stress/profiling: `res://scenes/test/StressRunScene.tscn`
- Cena legada tecnica: `res://gameplay/test/TestGaiaScene.tscn`
- Status consolidado: `READY_WITH_FOLLOW_UPS`

## Sistemas implementados

- Gaia com movimento, mira, dash e ataque direcional
- combate com `Area2D`, `Hitbox`, `Hurtbox` e `DamageResolver`
- Goblin pooled com perseguicao, ataque, dano, morte, XP e moeda
- XP direta, level-up e upgrades
- moedas fisicas com magnetismo
- HUD, feedbacks, resultado e save
- localizacao nativa Godot via `translation.csv`
- stress scene e overlay de metricas
- testes unitarios nativos em GDScript

## Interpretacao oficial de stress

- ~90 inimigos vivos: ~60 FPS medio
- ~120 inimigos vivos: ~50 FPS medio
- ~140 inimigos vivos: ~40 FPS
- ~180 inimigos vivos: ~30 FPS
- limite observado da stress scene atual: ~180 inimigos vivos

## Meta segura atual

- alvo normal de gameplay: `80-100` inimigos vivos
- ate `120` inimigos vivos e aceitavel com pressao
- acima de `140` inimigos vivos deve ser tratado como stress tecnico ou futura meta de otimizacao

## Proxima fase recomendada

- conteudo real de elite e boss
- nova arma
- HUD final
- otimizacao focada apenas se a meta de horda subir
