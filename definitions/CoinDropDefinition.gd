## Resource de configuração de moeda/drop coletável.
##
## Responsabilidades:
## - definir valor padrão da moeda;
## - configurar magnetismo;
## - configurar raio de coleta;
## - configurar comportamento inicial após o drop;
## - configurar aparência técnica/debug.
##
## Este resource permite balancear moedas sem alterar o script CoinDrop.
extends Resource
class_name CoinDropDefinition

## ID técnico único deste tipo de moeda/drop.
@export var id: String = "coin_default"

## Chave de localização para nome exibido, se necessário.
@export var display_name_key: String = "drop.coin.default.name"

## Valor padrão adicionado ao contador da run quando coletado.
@export var default_value: int = 1

## Distância a partir da qual a moeda começa a ser atraída pela Gaia.
@export var magnet_radius: float = 150.0

## Distância final para considerar a moeda coletada.
@export var collect_radius: float = 24.0

## Tempo inicial em que a moeda fica parada antes de poder ser magnetizada.
##
## Ajuda o drop a aparecer no chão antes de começar a se mover.
@export var initial_idle_seconds: float = 0.15

## Aceleração usada quando a moeda está sendo puxada pelo magnetismo.
@export var magnet_acceleration: float = 900.0

## Velocidade máxima da moeda durante magnetismo.
@export var max_magnet_speed: float = 520.0

## Raio visual usado para debug/desenho técnico da moeda.
@export var debug_radius: float = 8.0

## Cor principal da moeda no debug/placeholder.
@export var debug_color: Color = Color(1.0, 0.78, 0.18, 1.0)

## Cor de contorno usada no debug/placeholder.
@export var debug_outline_color: Color = Color(1.0, 1.0, 1.0, 0.95)

## Verifica se o resource possui configuração mínima válida.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and default_value > 0
