extends CanvasLayer

# Janela que abre por cima do jogo. Cobre as tres familias de enigma:
# documento, minijogo de deducao e fechadura numerica.

signal fechou

const FUNDO := Color(0.96, 0.95, 0.93)
const TINTA := Color(0.10, 0.10, 0.10)
const VERDE := Color(0.12, 0.31, 0.27)

var _painel: PanelContainer
var _titulo: Label
var _corpo: VBoxContainer

var _rodada := 0
var _intruso := -1

var _digitado := ""
var _visor: Label


func _ready() -> void:
	layer = 10
	visible = false

	var escurecer := ColorRect.new()
	escurecer.color = Color(0, 0, 0, 0.45)
	escurecer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escurecer)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	_painel = PanelContainer.new()
	_painel.custom_minimum_size = Vector2(620, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = FUNDO
	estilo.border_color = TINTA
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(22)
	_painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(_painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	_painel.add_child(coluna)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 22)
	_titulo.add_theme_color_override("font_color", TINTA)
	coluna.add_child(_titulo)

	_corpo = VBoxContainer.new()
	_corpo.add_theme_constant_override("separation", 10)
	coluna.add_child(_corpo)

	var rodape := Label.new()
	rodape.text = "ESC para fechar"
	rodape.add_theme_font_size_override("font_size", 12)
	rodape.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	coluna.add_child(rodape)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		fechar()
		get_viewport().set_input_as_handled()


func fechar() -> void:
	visible = false
	Audio.tocar("overlay_fechar")
	fechou.emit()


# ---------------------------------------------------------------- base

func _abrir(titulo: String) -> void:
	for filho in _corpo.get_children():
		filho.queue_free()
	_titulo.text = titulo
	if not visible:
		Audio.tocar("overlay_abrir")
	visible = true


func _texto(t: String, tamanho := 15) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", TINTA)
	_corpo.add_child(l)
	return l


func _botao(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 36)
	_corpo.add_child(b)
	return b


# ------------------------------------------------------ documentos

func abrir_documento(titulo: String, corpo: String) -> void:
	_abrir(titulo)
	_texto(corpo)


func abrir_quadro() -> void:
	_abrir("Quadro de avisos")
	_texto("Entre um comunicado sobre a geladeira e outro sobre estacionamento, há uma folha sem cabeçalho.")

	var grade := GridContainer.new()
	grade.columns = Estado.LETRAS.size()
	grade.add_theme_constant_override("h_separation", 14)
	_corpo.add_child(grade)

	for letra in Estado.LETRAS:
		var l := Label.new()
		l.text = letra
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		grade.add_child(l)
	for letra in Estado.LETRAS:
		var d := Label.new()
		d.text = str(Estado.cifra[letra])
		d.add_theme_font_size_override("font_size", 19)
		d.add_theme_color_override("font_color", TINTA)
		grade.add_child(d)

	_texto("Uma letra para cada dígito. Alguém achou que isso era discreto o suficiente.", 13)
	Estado.anotar("O quadro de avisos do setor 01 tem uma tabela de letra para dígito.")
	Estado.cumprir_marco(2)
	_checar_cruzamento()


func abrir_armario() -> void:
	_abrir("Armário 14")
	_texto("Uma etiqueta datilografada, colada por dentro da porta:")
	var l := _texto(Estado.bilhete, 40)
	l.add_theme_color_override("font_color", VERDE)
	_texto("Três letras, sem mais nada escrito.", 13)
	Estado.anotar("O armário 14 do setor 03 guarda um bilhete com três letras: " + Estado.bilhete + ".")
	Estado.cumprir_marco(2)
	_checar_cruzamento()


# O marco 3 e o momento em que dois moveis de setores diferentes
# se revelam parte do mesmo enigma.
func _checar_cruzamento() -> void:
	if Estado.foi_examinado(1, "Quadro de avisos") and Estado.foi_examinado(3, "Armário 14"):
		Estado.cumprir_marco(3)


func abrir_planta() -> void:
	_abrir("Planta de evacuação")
	_texto("O desenho mostra o andar inteiro. Nenhuma das saídas marcadas existe de verdade, com uma exceção: um elevador de serviço, no fim deste mesmo setor.")
	_texto("Abaixo do símbolo, escrito à mão: ACESSO NÍVEL 4.", 13)
	Estado.anotar("O elevador de serviço do setor 01 é a saída, e exige crachá nível 4.")
	Estado.mapa_mudou.emit()


# -------------------------------------------------- minijogo (terminal)

func abrir_terminal() -> void:
	_abrir("Terminal de refino")
	if Estado.partidas_terminal >= Estado.COTA_PARTIDAS:
		_texto("COTA DIÁRIA ATINGIDA. O terminal não aceita mais partidas hoje.")
		return
	_texto("Três rodadas seguidas. Prêmio: " + str(Estado.PREMIO_PARTIDA) + " fichas.")
	_texto("Partidas usadas: " + str(Estado.partidas_terminal) + " de " + str(Estado.COTA_PARTIDAS), 13)
	var b := _botao("Iniciar partida")
	b.pressed.connect(_iniciar_partida)
	Estado.anotar("O terminal do setor 02 paga fichas por partida vencida.")


func _iniciar_partida() -> void:
	Estado.partidas_terminal += 1
	_rodada = 0
	_proxima_rodada()


func _proxima_rodada() -> void:
	if _rodada >= 3:
		Estado.ganhar_fichas(Estado.PREMIO_PARTIDA)
		_abrir("Terminal de refino")
		_texto("PARTIDA VENCIDA.")
		_texto("Creditado: " + str(Estado.PREMIO_PARTIDA) + " fichas.")
		Estado.riscar("O terminal do setor 02 paga fichas por partida vencida.")
		return

	_abrir("Terminal de refino")
	_texto("RODADA " + str(_rodada + 1) + " DE 3", 13)

	var rodada := _gerar_rodada()
	_texto(rodada["texto"], 17)
	_intruso = rodada["intruso"]

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	_corpo.add_child(linha)

	for valor in rodada["opcoes"]:
		var b := Button.new()
		b.text = str(valor)
		b.custom_minimum_size = Vector2(110, 52)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(_responder.bind(valor))
		linha.add_child(b)

	_texto("Errar reinicia a partida. O terminal não explica a regra.", 12)


func _gerar_rodada() -> Dictionary:
	var tipo := randi() % 5
	var opcoes: Array = []
	var intruso := 0

	match tipo:
		0:
			var quadrados := [4, 9, 16, 25, 36, 49, 64, 81, 100, 121]
			quadrados.shuffle()
			opcoes = [quadrados[0], quadrados[1], quadrados[2]]
			intruso = int(quadrados[0]) + 3
			return {"texto": "Três são quadrados perfeitos. Marque o intruso.",
				"opcoes": _embaralhar(opcoes, intruso), "intruso": intruso}
		1:
			var base := (randi() % 20 + 3) * 5
			opcoes = [base, base + 5, base + 15]
			intruso = base + 7
			return {"texto": "Três são múltiplos de cinco. Marque o intruso.",
				"opcoes": _embaralhar(opcoes, intruso), "intruso": intruso}
		2:
			var p := (randi() % 30 + 5) * 2
			opcoes = [p, p + 2, p + 6]
			intruso = p + 3
			return {"texto": "Três são pares. Marque o intruso.",
				"opcoes": _embaralhar(opcoes, intruso), "intruso": intruso}
		3:
			var primos := [11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53]
			primos.shuffle()
			opcoes = [primos[0], primos[1], primos[2]]
			intruso = int(primos[0]) + 1
			return {"texto": "Três são primos. Marque o intruso.",
				"opcoes": _embaralhar(opcoes, intruso), "intruso": intruso}
		_:
			var b := randi() % 7 + 2
			opcoes = [b * 3, b * 3 + 3, b * 3 + 9]
			intruso = b * 3 + 2
			return {"texto": "Três são múltiplos de três. Marque o intruso.",
				"opcoes": _embaralhar(opcoes, intruso), "intruso": intruso}


func _embaralhar(opcoes: Array, intruso: int) -> Array:
	var todas := opcoes.duplicate()
	todas.append(intruso)
	todas.shuffle()
	return todas


func _responder(valor: int) -> void:
	if valor == _intruso:
		Audio.tocar("aceito")
		_rodada += 1
		_proxima_rodada()
	else:
		Audio.tocar("recusado")
		_abrir("Terminal de refino")
		_texto("RESPOSTA RECUSADA.")
		_texto("A partida foi reiniciada.")
		var b := _botao("Voltar")
		b.pressed.connect(abrir_terminal)


# ---------------------------------------------------- maquina e colega

func abrir_maquina() -> void:
	_abrir("Máquina de salgados")
	_texto("Fichas no bolso: " + str(Estado.fichas), 17)

	var b1 := _botao("Sanduíche — 2 fichas")
	b1.pressed.connect(_comprar_sanduiche)
	var b2 := _botao("Café — 1 ficha")
	b2.pressed.connect(_comprar_cafe)

	if Estado.tem_sanduiche:
		_texto("Você já está com um sanduíche.", 13)


func _comprar_sanduiche() -> void:
	if Estado.tem_sanduiche:
		Estado.aviso.emit("Você já tem um sanduíche.")
		return
	if not Estado.gastar_fichas(2):
		Audio.tocar("recusado")
		Estado.aviso.emit("Fichas insuficientes.")
		return
	Estado.tem_sanduiche = true
	Estado.bolso_mudou.emit()
	Audio.tocar("aceito")
	Estado.aviso.emit("Sanduíche no bolso.")
	abrir_maquina()


func _comprar_cafe() -> void:
	if not Estado.gastar_fichas(1):
		Audio.tocar("recusado")
		Estado.aviso.emit("Fichas insuficientes.")
		return
	# a armadilha proposital: o cafe nao serve para nada
	Audio.tocar("aceito")
	Estado.aviso.emit("O copo sai quente. E é só isso.")
	abrir_maquina()


func abrir_colega() -> void:
	_abrir("Colega da copa")
	if Estado.tem_chave:
		_texto("— Já te dei a chave. Some daqui antes que alguém veja.")
		return
	if Estado.tem_sanduiche:
		_texto("— Você trouxe comida. Não pergunto de onde.")
		_texto("Ela tira uma chave pequena do bolso do avental e empurra pela mesa.")
		Estado.tem_sanduiche = false
		Estado.tem_chave = true
		Estado.bolso_mudou.emit()
		Estado.mapa_mudou.emit()
		Audio.tocar("aceito")
		Estado.riscar("A colega da copa troca a chave do arquivo morto por comida.")
		Estado.anotar("A chave da colega abre a porta 06, no setor 03.")
	else:
		_texto("— Não saio daqui desde as sete. Se aparecer alguma coisa de comer, a gente conversa.")
		Estado.anotar("A colega da copa troca a chave do arquivo morto por comida.")


# ------------------------------------------------------------- cofre

func abrir_cofre() -> void:
	_abrir("Cofre do arquivo")
	if Estado.tem_cracha:
		_texto("O cofre está aberto e vazio.")
		return

	_digitado = ""
	_texto("Teclado de três dígitos. Sem trava por tentativa — mas também sem dica.", 13)

	_visor = Label.new()
	_visor.text = "_ _ _"
	_visor.add_theme_font_size_override("font_size", 34)
	_visor.add_theme_color_override("font_color", TINTA)
	_visor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_corpo.add_child(_visor)

	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	_corpo.add_child(grade)

	for t in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]:
		var b := Button.new()
		b.text = t
		b.custom_minimum_size = Vector2(120, 46)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_tecla.bind(t))
		grade.add_child(b)


func _tecla(t: String) -> void:
	if t == "C":
		Audio.tocar("tecla")
		_digitado = ""
	elif t == "OK":
		if _digitado == Estado.senha:
			Estado.tem_cracha = true
			Estado.bolso_mudou.emit()
			Estado.cumprir_marco(4)
			Audio.tocar("cracha_aprovado")
			Estado.riscar("O elevador de serviço do setor 01 é a saída, e exige crachá nível 4.")
			_abrir("Cofre do arquivo")
			_texto("A porta cede.")
			_texto("Dentro, um único crachá plastificado. NÍVEL 4.")
			return
		else:
			Audio.tocar("recusado")
			Estado.aviso.emit("O cofre recusa.")
			_digitado = ""
	elif _digitado.length() < 3:
		Audio.tocar("tecla")
		_digitado += t

	if is_instance_valid(_visor):
		var mostra := ""
		for i in 3:
			mostra += (_digitado[i] if i < _digitado.length() else "_") + " "
		_visor.text = mostra.strip_edges()


# ---------------------------------------------------------- elevador

func abrir_elevador() -> void:
	_abrir("Elevador de serviço")
	if Estado.tem_cracha:
		Audio.tocar("cracha_aprovado")
		Audio.tocar("elevador")
		_texto("O leitor apita uma vez. A luz fica verde.")
		_texto("As portas abrem para um corredor que você nunca viu.")
		Estado.cumprir_marco(5)
		Estado.venceu = true
	else:
		Audio.tocar("cracha_negado")
		_texto("Há um leitor de crachá ao lado do botão.")
		_texto("Você encosta o seu. A luz fica vermelha. NÍVEL INSUFICIENTE.")
		Estado.anotar("O elevador de serviço do setor 01 é a saída, e exige crachá nível 4.")
		Estado.mapa_mudou.emit()


func abrir_neutro(rotulo: String) -> void:
	_abrir(rotulo)
	_texto("Você olha com atenção. Não há nada aqui.")


func abrir_trancada() -> void:
	_abrir("Porta 06")
	Audio.tocar("porta_travada")
	_texto("Trancada. A fechadura é antiga, de chave, e não tem leitor de crachá.")
	Estado.anotar("A porta 06, no setor 03, está trancada por chave.")
