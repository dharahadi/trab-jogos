extends RefCounted

# Tabela de dados. Mexer aqui muda o jogo sem tocar em codigo.
#
# perimetro = comprimento do anel em pixels. O jogador anda em x, e
# quando passa do perimetro a posicao volta a zero.
# mapa = posicao do no no minimapa.
#
# tipos de movel: porta, quadro, planta, terminal, armario,
#                 maquina, colega, cofre, elevador, neutro

const SETORES := {
	1: {
		"nome": "Recepção",
		"perimetro": 1900.0,
		"mapa": Vector2(150, 34),
		"moveis": [
			{"x": 150.0, "rotulo": "Porta 02", "tipo": "porta", "destino": 2},
			{"x": 480.0, "rotulo": "Quadro de avisos", "tipo": "quadro"},
			{"x": 760.0, "rotulo": "Vaso", "tipo": "neutro"},
			{"x": 1050.0, "rotulo": "Planta de evacuação", "tipo": "planta"},
			{"x": 1380.0, "rotulo": "Porta 03", "tipo": "porta", "destino": 3},
			{"x": 1680.0, "rotulo": "Elevador de serviço", "tipo": "elevador"},
		],
	},
	2: {
		"nome": "Refino",
		"perimetro": 1500.0,
		"mapa": Vector2(58, 96),
		"moveis": [
			{"x": 180.0, "rotulo": "Porta 01", "tipo": "porta", "destino": 1},
			{"x": 620.0, "rotulo": "Terminal", "tipo": "terminal"},
			{"x": 980.0, "rotulo": "Bebedouro", "tipo": "neutro"},
			{"x": 1280.0, "rotulo": "Porta 05", "tipo": "porta", "destino": 5},
		],
	},
	3: {
		"nome": "Armários",
		"perimetro": 1500.0,
		"mapa": Vector2(242, 96),
		"moveis": [
			{"x": 160.0, "rotulo": "Porta 01", "tipo": "porta", "destino": 1},
			{"x": 560.0, "rotulo": "Armário 14", "tipo": "armario"},
			{"x": 900.0, "rotulo": "Mesa", "tipo": "neutro"},
			{"x": 1240.0, "rotulo": "Porta 06", "tipo": "porta", "destino": 6, "exige": "chave"},
		],
	},
	4: {
		"nome": "Copa",
		"perimetro": 1300.0,
		"mapa": Vector2(150, 206),
		"moveis": [
			{"x": 150.0, "rotulo": "Porta 05", "tipo": "porta", "destino": 5},
			{"x": 600.0, "rotulo": "Colega da copa", "tipo": "colega"},
			{"x": 980.0, "rotulo": "Banco", "tipo": "neutro"},
		],
	},
	5: {
		"nome": "Corredor de máquinas",
		"perimetro": 1400.0,
		"mapa": Vector2(58, 158),
		"moveis": [
			{"x": 170.0, "rotulo": "Porta 02", "tipo": "porta", "destino": 2},
			{"x": 620.0, "rotulo": "Máquina de salgados", "tipo": "maquina"},
			{"x": 1050.0, "rotulo": "Porta 04", "tipo": "porta", "destino": 4},
		],
	},
	6: {
		"nome": "Arquivo morto",
		"perimetro": 1200.0,
		"mapa": Vector2(242, 158),
		"moveis": [
			{"x": 150.0, "rotulo": "Porta 03", "tipo": "porta", "destino": 3},
			{"x": 650.0, "rotulo": "Cofre", "tipo": "cofre"},
		],
	},
}


# Tamanho do retangulo de cada tipo de movel, em pixels.
const TAMANHOS := {
	"porta": Vector2(70, 150),
	"quadro": Vector2(110, 80),
	"planta": Vector2(90, 70),
	"terminal": Vector2(80, 110),
	"armario": Vector2(80, 160),
	"maquina": Vector2(90, 150),
	"colega": Vector2(40, 90),
	"cofre": Vector2(90, 90),
	"elevador": Vector2(100, 160),
	"neutro": Vector2(50, 60),
}


# Quantos moveis com enigma cada setor tem. Usado pelo minimapa.
static func moveis_do_setor(numero: int) -> int:
	return SETORES[numero]["moveis"].size()


# Vizinhos de um setor, lidos das portas.
static func vizinhos(numero: int) -> Array:
	var lista: Array = []
	for m in SETORES[numero]["moveis"]:
		if m["tipo"] == "porta":
			lista.append(m["destino"])
	return lista
