extends Node2D

# Raiz do jogo. Monta o setor a partir da tabela de dados, cuida do
# corredor circular, da interacao e da troca de setor.

const Dados = preload("res://dados/setores.gd")

const CENTRO_X := 576.0     # o jogador fica sempre aqui
const CHAO_Y := 470.0
const VELOCIDADE := 160.0   # px/s. Perimetro 1900 da uma volta em ~12s
const RAIO_INTERACAO := 70.0
const ESPACO_LUMINARIA := 320.0

var setor_atual := 1
var perimetro := 1900.0
var posicao := 0.0          # posicao do jogador no anel, sempre em [0, perimetro)

var _mundo: Node2D
var _jogador: Node2D
var _hud: CanvasLayer
var _overlay: CanvasLayer
var _titulo: CanvasLayer
var _pausa: CanvasLayer

# cada item: { "no": Node2D, "x": float, "dados": Dictionary ou null, "etiqueta": Label }
var _itens: Array = []
var _alvo: Dictionary = {}
var _final_mostrado := false
var _comecou := false

var _andado := 0.0          # distancia acumulada, para detectar a primeira volta
var _passo_t := 0.0


func _ready() -> void:
	randomize()
	_construir_fundo()

	_mundo = Node2D.new()
	add_child(_mundo)

	_jogador = preload("res://scripts/jogador.gd").new()
	_jogador.position = Vector2(CENTRO_X, CHAO_Y)
	_jogador.z_index = 10
	add_child(_jogador)

	_hud = preload("res://scripts/hud.gd").new()
	add_child(_hud)

	_overlay = preload("res://scripts/overlay.gd").new()
	add_child(_overlay)
	_overlay.fechou.connect(_ao_fechar_overlay)

	_pausa = preload("res://scripts/pausa.gd").new()
	_pausa.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_pausa)
	_pausa.reiniciar_pedido.connect(_reiniciar)

	_titulo = preload("res://scripts/titulo.gd").new()
	add_child(_titulo)
	_titulo.comecou.connect(func(): _comecou = true)

	entrar_no_setor(1, 300.0)


# ------------------------------------------------------------- cenario

func _construir_fundo() -> void:
	var parede := ColorRect.new()
	parede.color = Color(0.976, 0.973, 0.965)
	parede.size = Vector2(1152, CHAO_Y)
	add_child(parede)

	var rodape := ColorRect.new()
	rodape.color = Color(0.85, 0.85, 0.84)
	rodape.position = Vector2(0, CHAO_Y - 10)
	rodape.size = Vector2(1152, 10)
	add_child(rodape)

	var chao := ColorRect.new()
	chao.color = Color(0.93, 0.93, 0.92)
	chao.position = Vector2(0, CHAO_Y)
	chao.size = Vector2(1152, 648 - CHAO_Y)
	add_child(chao)


func entrar_no_setor(numero: int, entrada_x: float) -> void:
	setor_atual = numero
	var setor: Dictionary = Dados.SETORES[numero]
	perimetro = setor["perimetro"]
	posicao = fposmod(entrada_x, perimetro)
	_andado = 0.0

	Estado.visitados[numero] = true
	Estado.mapa_mudou.emit()

	for filho in _mundo.get_children():
		filho.queue_free()
	_itens.clear()

	# luminarias do teto, repetidas ao longo de todo o anel
	var quantas := int(perimetro / ESPACO_LUMINARIA)
	for i in quantas:
		var luz := ColorRect.new()
		luz.color = Color(0.88, 0.89, 0.87)
		luz.size = Vector2(150, 10)
		luz.position = Vector2(-75, 40 - CHAO_Y)
		var no := Node2D.new()
		no.add_child(luz)
		_mundo.add_child(no)
		_itens.append({"no": no, "x": i * ESPACO_LUMINARIA, "dados": null, "etiqueta": null})

	# moveis
	for m in setor["moveis"]:
		var criado := _criar_movel(m)
		_mundo.add_child(criado["no"])
		_itens.append({"no": criado["no"], "x": m["x"], "dados": m, "etiqueta": criado["etiqueta"]})

	_hud.definir_setor(numero, setor["nome"])
	_posicionar()
	_atualizar_marcas()


func _criar_movel(m: Dictionary) -> Dictionary:
	var no := Node2D.new()
	var tamanho: Vector2 = Dados.TAMANHOS.get(m["tipo"], Vector2(60, 70))

	var caixa := ColorRect.new()
	caixa.size = tamanho
	caixa.position = Vector2(-tamanho.x / 2.0, -tamanho.y)
	if m["tipo"] == "neutro":
		caixa.color = Color(0.78, 0.78, 0.77)
	elif m["tipo"] == "colega":
		caixa.color = Color(0.35, 0.35, 0.35)
	else:
		caixa.color = Color(0.13, 0.13, 0.13)
	no.add_child(caixa)

	# plaquinha com o numero do setor, so nas portas
	if m["tipo"] == "porta":
		var placa := ColorRect.new()
		placa.color = Color(0.96, 0.95, 0.93)
		placa.size = Vector2(38, 20)
		placa.position = Vector2(-19, -tamanho.y - 26)
		no.add_child(placa)
		var num := Label.new()
		num.text = "%02d" % int(m["destino"])
		num.size = Vector2(38, 20)
		num.position = Vector2(-19, -tamanho.y - 26)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.add_theme_font_size_override("font_size", 12)
		num.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		no.add_child(num)

	var etiqueta := Label.new()
	etiqueta.text = m["rotulo"]
	etiqueta.size = Vector2(240, 20)
	etiqueta.position = Vector2(-120, 8)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 12)
	etiqueta.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	no.add_child(etiqueta)

	return {"no": no, "etiqueta": etiqueta}


# Movel ja examinado ganha um tique na etiqueta. E o terceiro medidor
# de progresso do pitch, junto com o mapa e o caderno.
func _atualizar_marcas() -> void:
	for item in _itens:
		if item["dados"] == null or item["etiqueta"] == null:
			continue
		var rotulo: String = item["dados"]["rotulo"]
		if Estado.foi_examinado(setor_atual, rotulo):
			item["etiqueta"].text = "✓ " + rotulo
			item["etiqueta"].add_theme_color_override("font_color", Color(0.12, 0.31, 0.27))
		else:
			item["etiqueta"].text = rotulo
			item["etiqueta"].add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))


# -------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if _overlay.visible or _titulo.visible or not _comecou:
		_jogador.andando = false
		return

	var direcao := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direcao -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direcao += 1.0

	if direcao != 0.0:
		var avanco := VELOCIDADE * delta
		posicao = fposmod(posicao + direcao * avanco, perimetro)
		_jogador.virado = int(direcao)

		# marco 1: a primeira volta completa
		_andado += avanco
		if _andado >= perimetro and not Estado.marcos.has(1):
			Estado.cumprir_marco(1)

		_passo_t += delta
		if _passo_t > 0.34:
			_passo_t = 0.0
			Audio.tocar("passo")

	_jogador.andando = direcao != 0.0

	_posicionar()
	_procurar_alvo()


# Distancia entre dois pontos do anel, sempre pelo caminho mais curto.
# E daqui que sai a ilusao: nada nunca esta "do outro lado".
func _delta_anel(de: float, para: float) -> float:
	return fposmod(para - de + perimetro / 2.0, perimetro) - perimetro / 2.0


func _posicionar() -> void:
	for item in _itens:
		var dx: float = _delta_anel(posicao, item["x"])
		var no: Node2D = item["no"]
		if absf(dx) > 700.0:
			no.visible = false
		else:
			no.visible = true
			no.position = Vector2(CENTRO_X + dx, CHAO_Y)


func _procurar_alvo() -> void:
	var melhor: Dictionary = {}
	var menor := RAIO_INTERACAO
	for item in _itens:
		if item["dados"] == null:
			continue
		var d: float = absf(_delta_anel(posicao, item["x"]))
		if d < menor:
			menor = d
			melhor = item["dados"]

	_alvo = melhor
	if _alvo.is_empty():
		_hud.definir_prompt("")
	else:
		_hud.definir_prompt("E  ·  " + str(_alvo["rotulo"]))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if not _comecou:
		return

	if event.keycode == KEY_ESCAPE and not _overlay.visible:
		if _pausa.visible:
			_pausa.fechar()
		else:
			_pausa.abrir()
		return

	if event.keycode == KEY_R and Estado.venceu:
		_reiniciar()
		return

	if event.keycode == KEY_E and not _overlay.visible and not _alvo.is_empty():
		_interagir(_alvo)


# ---------------------------------------------------------- interacao

func _interagir(m: Dictionary) -> void:
	_jogador.estender_braco()
	Estado.marcar_examinado(setor_atual, m["rotulo"])
	_atualizar_marcas()

	match m["tipo"]:
		"porta":
			if m.get("exige", "") == "chave" and not Estado.tem_chave:
				_overlay.abrir_trancada()
			else:
				Audio.tocar("porta_abrir")
				_atravessar(m["destino"])
		"quadro":
			_overlay.abrir_quadro()
		"armario":
			_overlay.abrir_armario()
		"planta":
			_overlay.abrir_planta()
		"terminal":
			_overlay.abrir_terminal()
		"maquina":
			_overlay.abrir_maquina()
		"colega":
			_overlay.abrir_colega()
		"cofre":
			_overlay.abrir_cofre()
		"elevador":
			_overlay.abrir_elevador()
		_:
			_overlay.abrir_neutro(m["rotulo"])


func _atravessar(destino: int) -> void:
	# chega ao lado da porta que volta para o setor de onde veio
	var entrada := 300.0
	for m in Dados.SETORES[destino]["moveis"]:
		if m["tipo"] == "porta" and m.get("destino", -1) == setor_atual:
			entrada = m["x"] + 90.0
			break
	entrar_no_setor(destino, entrada)


func _ao_fechar_overlay() -> void:
	if Estado.venceu and not _final_mostrado:
		_final_mostrado = true
		_mostrar_final()


func _mostrar_final() -> void:
	var linhas := "Saiu em %d min %02d s.\n\n" % [int(Estado.tempo) / 60, int(Estado.tempo) % 60]
	linhas += "Setores abertos: %d de 6\n" % Estado.visitados.size()
	linhas += "Móveis examinados: %d\n" % Estado.examinados.size()
	linhas += "Fichas que sobraram: %d\n\n" % Estado.fichas
	linhas += "MARCOS DA PARTIDA\n"
	for numero in [1, 2, 3, 4, 5]:
		linhas += ("✓  " if Estado.marcos.has(numero) else "—  ") + Estado.MARCOS[numero] + "\n"
	linhas += "\nA senha era %s, do bilhete %s.\n" % [Estado.senha, Estado.bilhete]
	linhas += "\nR para bater o ponto de novo, com outra cifra."
	_overlay.abrir_documento("Fim de expediente", linhas)


func _reiniciar() -> void:
	Estado.reiniciar()
	_final_mostrado = false
	_overlay.visible = false
	entrar_no_setor(1, 300.0)
