## Resource de configuração do drop físico de moeda.
##
## Controla valor, magnetismo, coleta e visual técnico das moedas
## que podem surgir ao derrotar inimigos.
##
## A moeda pertence à run atual e só é contabilizada após coleta física.
extends Resource
class_name CoinDropDefinition

## ID técnico da configuração de moeda.
@export var id: String = "coin_default"

## Chave de localização utilizada para nome da moeda.
@export var display_name_key: String = "drop.coin.default.name"

## Valor padrão concedido quando a moeda é coletada.
@export var default_value: int = 1

## Distância base na qual a moeda começa a ser atraída pela Queen.
@export var magnet_radius: float = 150.0

## Distância base na qual a moeda é considerada coletada.
@export var collect_radius: float = 24.0

## Tempo inicial em que a moeda permanece parada após nascer.
##
## Esse intervalo melhora legibilidade visual do drop antes do magnetismo.
@export var initial_idle_seconds: float = 0.15

## Aceleração utilizada quando a moeda está sendo atraída.
@export var magnet_acceleration: float = 900.0

## Velocidade máxima alcançada pela moeda durante magnetismo.
@export var max_magnet_speed: float = 520.0

## Raio do placeholder visual utilizado durante o protótipo.
@export var debug_radius: float = 8.0

## Cor principal do placeholder visual da moeda.
@export var debug_color: Color = Color(1.0, 0.78, 0.18, 1.0)

## Cor de contorno do placeholder visual da moeda.
@export var debug_outline_color: Color = Color(1.0, 1.0, 1.0, 0.95)

## Verifica se a definição possui ID e valor padrão válidos.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and default_value > 0
