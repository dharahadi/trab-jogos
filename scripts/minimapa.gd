extends Control

# Minimapa que se desenha sozinho. Mostra os setores ja encontrados,
# os que sao conhecidos mas nao visitados, e a porta trancada.
# Cada ponto ao redor do no e um movel ja examinado naquele setor.

const Dados = preload("res://dados/setores.gd")

const TINTA := Color(0.16, 0.16, 0.16)
const VERDE := Color(0.12, 0.31, 0.27)
const APAGADO := Color(0.66, 0.66, 0.66)

var setor_atual := 1


func _ready() -> void:
	custom_minimum_size = Vector2(276, 240)
	Estado.mapa_mudou.connect(queue_redraw)


func definir_setor(numero: int) -> void:
	setor_atual = numero
	queue_redraw()


# Um setor e conhecido quando da para ver a porta dele de algum
# lugar ja visitado, mesmo sem nunca ter entrado.
func _conhecido(numero: int) -> bool:
	if Estado.visitados.has(numero):
		return true
	for visitado in Estado.visitados:
		if Dados.vizinhos(visitado).has(numero):
			return true
	return false


func _draw() -> void:
	# arestas primeiro, para ficarem atras dos nos
	for numero in Dados.SETORES:
		if not Estado.visitados.has(numero):
			continue
		var origem: Vector2 = Dados.SETORES[numero]["mapa"]
		for vizinho in Dados.vizinhos(numero):
			var destino: Vector2 = Dados.SETORES[vizinho]["mapa"]
			var trancada: bool = vizinho == 6 and not Estado.tem_chave
			if trancada:
				_tracejada(origem, destino, APAGADO)
			else:
				draw_line(origem, destino, APAGADO, 1.5)

	for numero in Dados.SETORES:
		if not _conhecido(numero):
			continue
		var p: Vector2 = Dados.SETORES[numero]["mapa"]
		var visitado: bool = Estado.visitados.has(numero)
		var atual: bool = numero == setor_atual

		if atual:
			draw_circle(p, 17.0, VERDE)
			_rotulo(p, "%02d" % numero, Color(1, 1, 1))
		elif visitado:
			draw_circle(p, 15.0, Color(1, 1, 1))
			draw_arc(p, 15.0, 0, TAU, 28, TINTA, 1.5)
			_rotulo(p, "%02d" % numero, TINTA)
		else:
			draw_arc(p, 14.0, 0, TAU, 28, APAGADO, 1.5)
			_rotulo(p, "?", APAGADO)

		# um ponto por movel examinado neste setor
		if visitado:
			var total: int = Dados.moveis_do_setor(numero)
			var vistos: int = Estado.examinados_no_setor(numero)
			for i in total:
				var ang: float = -PI / 2.0 + TAU * float(i) / float(total)
				var ponto: Vector2 = p + Vector2(cos(ang), sin(ang)) * 24.0
				if i < vistos:
					draw_circle(ponto, 2.5, VERDE)
				else:
					draw_arc(ponto, 2.5, 0, TAU, 10, APAGADO, 1.0)

	# a saida, pendurada no setor 01
	var s1: Vector2 = Dados.SETORES[1]["mapa"]
	if Estado.marcos.has(1) or Estado.foi_examinado(1, "Planta de evacuação"):
		var caixa := Rect2(s1 + Vector2(-96, -12), Vector2(56, 22))
		draw_rect(caixa, Color(1, 1, 1))
		draw_rect(caixa, VERDE, false, 1.5)
		var fonte := ThemeDB.fallback_font
		draw_string(fonte, caixa.position + Vector2(9, 16), "SAÍDA",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VERDE)
		draw_line(caixa.position + Vector2(56, 11), s1 - Vector2(17, 0), APAGADO, 1.5)


func _rotulo(centro: Vector2, texto: String, cor: Color) -> void:
	var fonte := ThemeDB.fallback_font
	var tam := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(fonte, centro - Vector2(tam.x / 2.0, -4), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cor)


func _tracejada(de: Vector2, para: Vector2, cor: Color) -> void:
	var total := de.distance_to(para)
	var passo := 7.0
	var dir := (para - de).normalized()
	var d := 0.0
	while d < total:
		var fim: float = minf(d + 4.0, total)
		draw_line(de + dir * d, de + dir * fim, cor, 1.5)
		d += passo
