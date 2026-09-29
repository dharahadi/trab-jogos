extends Node2D

# O jogador fica sempre parado no centro da tela. Quem se move e o
# cenario. Isso e o que faz o corredor circular nao ter emenda visivel:
# nao existe camera para pular quando a volta fecha.

const COR := Color(0.1, 0.1, 0.1)

var andando := false
var virado := 1          # 1 direita, -1 esquerda
var _t := 0.0            # tempo, usado na respiracao e no passo


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# respiracao leve quando parado
	var resp := 0.0 if andando else sin(_t * 2.0) * 1.2
	var quadril := Vector2(0, -46 + resp)
	var ombro := Vector2(0, -78 + resp)
	var cabeca := Vector2(0, -92 + resp)

	draw_circle(cabeca, 11.0, Color(1, 1, 1))
	draw_arc(cabeca, 11.0, 0, TAU, 24, COR, 2.0)
	draw_line(ombro, quadril, COR, 2.0)

	if andando:
		# pernas alternando
		var passo := sin(_t * 10.0) * 14.0
		draw_line(quadril, Vector2(passo, 0), COR, 2.0)
		draw_line(quadril, Vector2(-passo, 0), COR, 2.0)
		draw_line(ombro, Vector2(-passo * 0.5, -58 + resp), COR, 2.0)
		draw_line(ombro, Vector2(passo * 0.5, -58 + resp), COR, 2.0)
	else:
		draw_line(quadril, Vector2(-7, 0), COR, 2.0)
		draw_line(quadril, Vector2(7, 0), COR, 2.0)
		draw_line(ombro, Vector2(-9, -58 + resp), COR, 2.0)
		draw_line(ombro, Vector2(9, -58 + resp), COR, 2.0)


func estender_braco() -> void:
	# usado ao interagir: por enquanto so um piscar de posicao
	_t = 0.0
