# Lifecycle — Boot do Projeto

## Fluxo atual

```txt
Godot abre Main.tscn
↓
App autoload inicializa
↓
LocalizationManager carrega idioma
↓
SaveManager carrega/cria save
↓
InputManager garante input actions
↓
Main.gd carrega TestGaiaScene.tscn
```

## Logs esperados

```txt
[App] Boot: Queen Survivors v0.1.0-module-1
[LocalizationManager] Idioma carregado: pt_br
[SaveManager] Save carregado.
[InputManager] Ready.
[Main] Cena inicial carregada: res://gameplay/test/TestGaiaScene.tscn
```

## Responsabilidade do Main

`Main` é um carregador de cena. Ele não deve conter regra da run.

## Responsabilidade da cena inicial

`TestGaiaScene` compõe a arena técnica atual.
