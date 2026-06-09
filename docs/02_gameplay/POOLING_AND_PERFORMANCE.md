# Pooling And Performance

## PoolManager

`PoolManager` e a base atual para reuso de objetos de alta rotacao.

## Objetos pooled

- inimigos
- moedas
- hitbox temporaria da arma
- visual temporario da arma
- floating combat text

## Hardening ja aplicado

- reset de estado no reuso
- desligamento de `process` e `physics_process` quando inativo
- desativacao de `Area2D.monitoring` quando inativo
- limpeza de tweens e estado visual

## Stress result oficial

- ~90 vivos: ~60 FPS medio
- ~120 vivos: ~50 FPS medio
- ~140 vivos: ~40 FPS
- ~180 vivos: ~30 FPS

## Meta segura atual

- gameplay normal: `80-100` inimigos vivos
- `120` ainda aceitavel com pressao
- acima de `140` exige tratar como stress tecnico ou abrir PR de otimizacao focada

## O que nao fazer agora

- nao otimizar por especulacao
- nao piorar o jogo normal para ganhar FPS de stress
- nao abrir refactor grande sem evidencia do profiler
