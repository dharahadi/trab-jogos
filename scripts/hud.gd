extends CanvasLayer

# Interface que fica sempre na tela: cabecalho do setor, prompt de
# interacao, aviso deslizante e o painel lateral com mapa, bolso e
# caderno.

const TINTA := Color(0.10, 0.10, 0.10)
const APAGADO := Color(0.55, 0.55, 0.55)
const VERDE := Color(0.12, 0.31, 0.27)

var minimapa: Control

var _cabecalho: Label
var _prompt: Label
var _aviso: Label
var _bolso: Label
var _caderno: VBoxContainer
var _aviso_t := 0.0


func _ready() -> void:
	layer = 5

	_cabecalho = Label.new()
	_cabecalho.position = Vector2(24, 18)
	_cabecalho.add_theme_font_size_override("font_size", 14)
	_cabecalho.add_theme_color_override("font_color", APAGADO)
	add_child(_cabecalho)

	_aviso = Label.new()
	_aviso.position = Vector2(24, 40)
	_aviso.add_theme_font_size_override("font_size", 14)
	_aviso.add_theme_color_override("font_color", VERDE)
	add_child(_aviso)

	_prompt = Label.new()
	_prompt.position = Vector2(0, 556)
	_prompt.size = Vector2(1152, 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 15)
	_prompt.add_theme_color_override("font_color", TINTA)
	add_child(_prompt)

	var dica := Label.new()
	dica.position = Vector2(24, 614)
	dica.add_theme_font_size_override("font_size", 11)
	dica.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	dica.text = "← →  andar     E  interagir     ESC  pausa"
	add_child(dica)

	# painel lateral
	var painel := PanelContainer.new()
	painel.position = Vector2(824, 18)
	painel.custom_minimum_size = Vector2(304, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0.84)
	estilo.border_color = Color(0.82, 0.82, 0.82)
	estilo.set_border_width_all(1)
	estilo.set_content_margin_all(14)
	painel.add_theme_stylebox_override("panel", estilo)
	add_child(painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	painel.add_child(coluna)

	coluna.add_child(_titulo("MAPA"))
	minimapa = preload("res://scripts/minimapa.gd").new()
	coluna.add_child(minimapa)

	coluna.add_child(_titulo("BOLSO"))
	_bolso = Label.new()
	_bolso.add_theme_font_size_override("font_size", 14)
	_bolso.add_theme_color_override("font_color", TINTA)
	coluna.add_child(_bolso)

	coluna.add_child(_titulo("CADERNO"))
	_caderno = VBoxContainer.new()
	_caderno.add_theme_constant_override("separation", 6)
	coluna.add_child(_caderno)

	Estado.bolso_mudou.connect(_atualizar_bolso)
	Estado.caderno_mudou.connect(_atualizar_caderno)
	Estado.aviso.connect(mostrar_aviso)
	Estado.marco_cumprido.connect(_ao_cumprir_marco)

	_atualizar_bolso()
	_atualizar_caderno()


func _titulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", APAGADO)
	return l


func _process(delta: float) -> void:
	if _aviso_t > 0.0:
		_aviso_t -= delta
		if _aviso_t <= 0.0:
			_aviso.text = ""


func definir_setor(numero: int, nome: String) -> void:
	_cabecalho.text = "SETOR %02d - %s" % [numero, nome.to_upper()]
	minimapa.definir_setor(numero)


func definir_prompt(texto: String) -> void:
	_prompt.text = texto


func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	_aviso_t = 2.8


func _ao_cumprir_marco(_numero: int, texto: String) -> void:
	mostrar_aviso(texto)


func _atualizar_bolso() -> void:
	var linhas := []
	linhas.append("Fichas: " + str(Estado.fichas))
	linhas.append("Sanduíche: " + ("sim" if Estado.tem_sanduiche else "—"))
	linhas.append("Chave do arquivo: " + ("sim" if Estado.tem_chave else "—"))
	linhas.append("Crachá nível 4: " + ("sim" if Estado.tem_cracha else "—"))
	_bolso.text = "\n".join(linhas)


func _atualizar_caderno() -> void:
	for filho in _caderno.get_children():
		filho.queue_free()
	if Estado.caderno.is_empty():
		var vazio := Label.new()
		vazio.text = "(nada anotado ainda)"
		vazio.add_theme_font_size_override("font_size", 12)
		vazio.add_theme_color_override("font_color", APAGADO)
		_caderno.add_child(vazio)
		return
	for entrada in Estado.caderno:
		var l := Label.new()
		l.text = ("✓ " if entrada["resolvido"] else "• ") + entrada["texto"]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(276, 0)
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", APAGADO if entrada["resolvido"] else TINTA)
		_caderno.add_child(l)
